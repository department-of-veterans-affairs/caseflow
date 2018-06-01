import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import CaseTitle from './CaseTitle';
import SelectCheckoutFlowDropdown from './components/SelectCheckoutFlowDropdown';
import TabWindow from '../components/TabWindow';
import { CATEGORIES } from './constants';
import { DateString } from '../util/DateUtil';

import { clearActiveAppealAndTask } from './CaseDetail/CaseDetailActions';
import { pushBreadcrumb, resetBreadcrumbs } from './uiReducer/uiActions';

const subHeadStyling = css({ marginBottom: '2rem' });

class QueueDetailView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.clearActiveAppealAndTask();
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
    const appeal = this.props.appeal.attributes;
    const basicSubHeading = `Docket Number: ${appeal.docket_number}, Assigned to ${appeal.location_code}`;

    if (this.props.task) {
      const task = this.props.task.attributes;

      if (this.props.userRole === 'Judge') {
        if (!task.assigned_by_first_name || !task.assigned_by_last_name || !task.document_id) {
          return basicSubHeading;
        }

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

    return basicSubHeading;
  }

  getCheckoutFlowDropdown = () => {
    const {
      appeal,
      vacolsId,
      featureToggles,
      loadedQueueAppealIds
    } = this.props;

    if (featureToggles.phase_two && loadedQueueAppealIds.includes(appeal.attributes.vacols_id)) {
      return <SelectCheckoutFlowDropdown vacolsId={vacolsId} />;
    }

    return null;
  }

  render = () => <AppSegment filledBackground>
    <CaseTitle appeal={this.props.appeal} {...this.props} />
    <p className="cf-lead-paragraph" {...subHeadStyling}>{this.subHead()}</p>
    {this.getCheckoutFlowDropdown()}
    <TabWindow
      name="queue-tabwindow"
      tabs={this.tabs()} />
  </AppSegment>;
}

QueueDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired,
  featureToggles: PropTypes.object,
  userRole: PropTypes.string
};

const mapStateToProps = (state) => ({
  appeal: state.caseDetail.activeAppeal,
  ..._.pick(state.ui, 'breadcrumbs', 'featureToggles'),
  task: state.caseDetail.activeTask,
  loadedQueueAppealIds: Object.keys(state.queue.loadedQueue.appeals)
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearActiveAppealAndTask,
  pushBreadcrumb,
  resetBreadcrumbs
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueDetailView);
