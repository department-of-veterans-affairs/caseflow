import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import _ from 'lodash';

import { withRouter } from 'react-router-dom';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ReaderLink from './ReaderLink';
import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import TabWindow from '../components/TabWindow';
import SearchableDropdown from '../components/SearchableDropdown';

import { fullWidth, CATEGORIES, DECISION_TYPES } from './constants';
import { DateString } from '../util/DateUtil';
import {
  setCaseReviewActionType,
  startEditingAppeal,
  cancelEditingAppeal,
  resetDecisionOptions
} from './QueueActions';
import {
  pushBreadcrumb,
  resetBreadcrumbs
} from './uiReducer/uiActions';

const headerStyling = css({ marginBottom: '0.5rem' });
const subHeadStyling = css({ marginBottom: '2rem' });
const dropdownStyling = css({ minHeight: 0 });

const draftDecisionOptions = [{
  label: 'Decision Ready for Review',
  value: 'decision'
}, {
  label: 'OMO Ready for Review',
  value: 'omo'
}];

class QueueDetailView extends React.PureComponent {
  componentDidMount = () => {
    this.props.resetBreadcrumbs();
    this.props.pushBreadcrumb({
      breadcrumb: 'Your Queue',
      path: '/'
    }, {
      breadcrumb: this.props.appeal.attributes.veteran_full_name,
      path: `/tasks/${this.props.vacolsId}`
    });
  }

  changeRoute = (props) => {
    const {
      vacolsId,
      history
    } = this.props;
    let route = 'dispositions';
    let decisionType = DECISION_TYPES.DRAFT_DECISION;

    if (props.value === 'omo') {
      route = 'submit';
      decisionType = DECISION_TYPES.OMO_REQUEST;
    }

    this.props.resetDecisionOptions();
    if (this.props.changedAppeals.includes(vacolsId)) {
      this.props.cancelEditingAppeal(vacolsId);
    }
    this.props.startEditingAppeal(vacolsId);
    this.props.setCaseReviewActionType(decisionType);
    history.push(`${history.location.pathname}/${route}`, { prev: 'detail' });
  }

  render = () => {
    const {
      appeal: { attributes: appeal },
      task: { attributes: task }
    } = this.props;
    const tabs = [{
      label: 'Appeal',
      page: <AppealDetail appeal={this.props.appeal} />
    }, {
      label: `Appellant (${appeal.appellant_full_name || appeal.veteran_full_name})`,
      page: <AppellantDetail appeal={this.props.appeal} />
    }];

    const readerLinkMsg = appeal.docCount ?
      `Open ${appeal.docCount.toLocaleString()} documents in Caseflow Reader` :
      'Open documents in Caseflow Reader';

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(headerStyling, fullWidth)}>
        {appeal.veteran_full_name} ({appeal.vbms_id})
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>
        Assigned to you {task.added_by_name ? `by ${task.added_by_name}` : ''} on&nbsp;
        <DateString date={task.assigned_on} dateFormat="MM/DD/YY" />.
        Due <DateString date={task.due_on} dateFormat="MM/DD/YY" />.
      </p>
      <ReaderLink
        vacolsId={this.props.vacolsId}
        message={readerLinkMsg}
        analyticsSource={CATEGORIES.QUEUE_TASK}
        redirectUrl={window.location.pathname}
        taskType="Draft Decision" />
      {this.props.featureToggles.phase_two && <SearchableDropdown
        name="Select an action"
        placeholder="Select an action&hellip;"
        options={draftDecisionOptions}
        onChange={this.changeRoute}
        hideLabel
        dropdownStyling={dropdownStyling} />}
      <TabWindow
        name="queue-tabwindow"
        tabs={tabs} />
    </AppSegment>;
  };
}

QueueDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state, ownProps) => ({
  appeal: state.queue.loadedQueue.appeals[ownProps.vacolsId],
  task: state.queue.loadedQueue.tasks[ownProps.vacolsId],
  changedAppeals: _.keys(state.queue.pendingChanges.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setCaseReviewActionType,
  startEditingAppeal,
  cancelEditingAppeal,
  resetDecisionOptions,
  pushBreadcrumb,
  resetBreadcrumbs
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QueueDetailView));
