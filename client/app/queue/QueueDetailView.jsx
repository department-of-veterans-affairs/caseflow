import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';
import TabWindow from '../components/TabWindow';
import { fullWidth, CATEGORIES } from './constants';
import ReaderLink from './ReaderLink';
import { DateString } from '../util/DateUtil';

import { clearActiveAppealAndTask } from './CaseDetail/CaseDetailActions';
import { pushBreadcrumb, resetBreadcrumbs, setBreadcrumbs } from './uiReducer/uiActions';

const headerStyling = css({ marginBottom: '0.5rem' });
const subHeadStyling = css({ marginBottom: '2rem' });

class QueueDetailView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.clearActiveAppealAndTask();
    this.props.setBreadcrumbs();
  }

  componentDidMount = () => {
    if (!this.props.breadcrumbs.length) {
      this.props.resetBreadcrumbs(this.props.appeal.attributes.veteran_full_name, this.props.vacolsId);
    }
  }

  tabs = () => {
    const appeal = this.props.appeal;

    return [{
      label: 'Appeal',
      page: <AppealDetail appeal={appeal} analyticsSource={CATEGORIES.QUEUE_TASK} />
    }, {
      label: `Appellant (${appeal.attributes.appellant_full_name || appeal.attributes.veteran_full_name})`,
      page: <AppellantDetail appeal={appeal} analyticsSource={CATEGORIES.QUEUE_TASK} />
    }];
  }

  subHead = () => {
    if (this.props.task) {
      const task = this.props.task.attributes;

      if (this.props.userRole === 'Judge') {
        const firstInitial = String.fromCodePoint(task.assigned_by_first_name.codePointAt(0));
        const nameAbbrev = `${firstInitial}. ${task.assigned_by_last_name}`;

        return <React.Fragment>
          Prepared by {nameAbbrev}<br />
          Document ID: {task.document_id}
        </React.Fragment>;
      }

      return <React.Fragment>
        Assigned to you {task.added_by_name ? `by ${task.added_by_name}` : ''} on&nbsp;
        <DateString date={task.assigned_on} dateFormat="MM/DD/YY" />.
        Due <DateString date={task.due_on} dateFormat="MM/DD/YY" />.
      </React.Fragment>;
    }

    const appeal = this.props.appeal.attributes;

    return `Docket Number: ${appeal.docket_number}, Assigned to ${appeal.location_code}`;
  }

  render = () => {
    const appeal = this.props.appeal.attributes;

    return <AppSegment filledBackground>
      <h1 className="cf-push-left" {...css(headerStyling, fullWidth)}>
        {appeal.veteran_full_name} ({appeal.vbms_id})
      </h1>
      <p className="cf-lead-paragraph" {...subHeadStyling}>{this.subHead()}</p>
      <ReaderLink
        vacolsId={this.props.vacolsId}
        analyticsSource={CATEGORIES.QUEUE_TASK}
        redirectUrl={window.location.pathname}
        appeal={this.props.appeal}
        taskType="Draft Decision"
        longMessage />
      {this.props.featureToggles.phase_two && <SelectCheckoutFlowDropdown vacolsId={this.props.vacolsId} />}
      <TabWindow
        name="queue-tabwindow"
        tabs={this.tabs()} />
    </AppSegment>;
  };
}

QueueDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  featureToggles: PropTypes.object,
  userRole: PropTypes.string
};

const mapStateToProps = (state) => ({
  appeal: state.caseDetail.activeAppeal,
  breadcrumbs: state.ui.breadcrumbs,
  task: state.caseDetail.activeTask
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearActiveAppealAndTask,
  pushBreadcrumb,
  resetBreadcrumbs,
  setBreadcrumbs
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueDetailView);
