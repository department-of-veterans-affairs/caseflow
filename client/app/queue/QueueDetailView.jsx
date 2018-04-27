import { css } from 'glamor';
import _ from 'lodash';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import AppealDetail from './AppealDetail';
import AppellantDetail from './AppellantDetail';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import SearchableDropdown from '../components/SearchableDropdown';
import TabWindow from '../components/TabWindow';
import { fullWidth, CATEGORIES, DECISION_TYPES } from './constants';
import { LOGO_COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';
import ApiUtil from '../util/ApiUtil';
import { DateString } from '../util/DateUtil';

import {
  clearActiveCaseAndTask,
  setActiveCase,
  setActiveTask,
  setDocumentCount
} from './CaseDetail/CaseDetailActions';
import {
  setCaseReviewActionType,
  stageAppeal,
  checkoutStagedAppeal,
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
  value: DECISION_TYPES.DRAFT_DECISION
}, {
  label: 'OMO Ready for Review',
  value: DECISION_TYPES.OMO_REQUEST
}];

class QueueDetailView extends React.PureComponent {
  componentWillUnmount = () => this.props.clearActiveCaseAndTask();

  componentDidMount = () => this.props.resetBreadcrumbs();

  setBreadcrumbs = () => {
    if (this.props.breadcrumbs.length) {
      return;
    }
    if (this.props.task) {
      this.props.pushBreadcrumb({
        breadcrumb: 'Your Queue',
        path: '/'
      }, {
        breadcrumb: this.props.appeal.attributes.veteran_full_name,
        path: `/appeals/${this.props.vacolsId}`
      });
    } else if (this.props.appeal) {
      this.props.pushBreadcrumb({
        breadcrumb: `< Back to ${this.props.appeal.attributes.veteran_full_name}'s case list`,
        path: '/'
      });
    }
  }

  loadCaseDetails = () => {
    if (this.props.appeal) {
      return Promise.resolve();
    }

    const loadedQueue = this.props.loadedQueue;

    if (loadedQueue.appeals && loadedQueue.appeals[this.props.vacolsId]) {
      this.props.setActiveCase(loadedQueue.appeals[this.props.vacolsId]);

      if (loadedQueue.tasks && loadedQueue.tasks[this.props.vacolsId]) {
        this.props.setActiveTask(loadedQueue.tasks[this.props.vacolsId]);
      }

      return Promise.resolve();
    }

    return ApiUtil.get(`/queue/appeals/${this.props.vacolsId}`).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setActiveCase(resp.appeal);
    });
  }

  populateActiveCaseDocumentCount = () => {
    if (!this.props.appeal || this.props.docCount) {
      return;
    }

    const appeal = this.props.appeal.attributes;

    if (appeal.docCount) {
      this.props.setDocumentCount(appeal.docCount);

      return;
    }

    const requestOptions = {
      withCredentials: true,
      timeout: true,
      headers: { 'FILE-NUMBER': appeal.vbms_id }
    };

    ApiUtil.get(appeal.number_of_documents_url, requestOptions).then((response) => {
      const resp = JSON.parse(response.text);

      this.props.setDocumentCount(resp.data.attributes.documents.length);
    });
  }

  changeRoute = (props) => {
    const {
      vacolsId,
      history,
      appeal: { attributes: { issues } }
    } = this.props;
    const decisionType = props.value;
    const route = decisionType === DECISION_TYPES.OMO_REQUEST ? 'submit' : 'dispositions';

    this.props.resetDecisionOptions();
    if (this.props.changedAppeals.includes(vacolsId)) {
      this.props.checkoutStagedAppeal(vacolsId);
    }

    if (decisionType === DECISION_TYPES.DRAFT_DECISION) {
      this.props.stageAppeal(vacolsId, {
        issues: _.map(issues, (issue) => _.set(issue, 'disposition', null))
      });
    } else {
      this.props.stageAppeal(vacolsId);
    }
    this.props.setCaseReviewActionType(decisionType);
    history.push(`${history.location.pathname}/${route}`);
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

      return <React.Fragment>
        Assigned to you {task.added_by_name ? `by ${task.added_by_name}` : ''} on&nbsp;
        <DateString date={task.assigned_on} dateFormat="MM/DD/YY" />.
        Due <DateString date={task.due_on} dateFormat="MM/DD/YY" />.
      </React.Fragment>;
    }

    const appeal = this.props.appeal.attributes;

    return `Docket Number: ${appeal.docket_number}, Assigned to ${appeal.location_code}`;
  }

  showCaseDetails = () => {
    if (!this.props.appeal) {
      return null;
    }

    this.populateActiveCaseDocumentCount();
    this.setBreadcrumbs();

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
        docCount={this.props.docCount}
        taskType="Draft Decision"
        longMessage />
      {this.props.featureToggles.phase_two && this.props.task && <SearchableDropdown
        name="Select an action"
        placeholder="Select an action&hellip;"
        options={draftDecisionOptions}
        onChange={this.changeRoute}
        hideLabel
        dropdownStyling={dropdownStyling} />}
      <TabWindow
        name="queue-tabwindow"
        tabs={this.tabs()} />
    </AppSegment>;
  };

  render = () => {
    const failStatusMessageChildren = <div>
      Caseflow was unable to load case details for this case.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    return <LoadingDataDisplay
      createLoadPromise={this.loadCaseDetails}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: 'Loading case details...'
      }}
      failStatusMessageProps={{ title: 'Unable to load case details' }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.showCaseDetails()}
    </LoadingDataDisplay>;
  }
}

QueueDetailView.propTypes = {
  vacolsId: PropTypes.string.isRequired
};

const mapStateToProps = (state) => ({
  appeal: state.caseDetail.activeCase,
  breadcrumbs: state.ui.breadcrumbs,
  changedAppeals: _.keys(state.queue.stagedChanges.appeals),
  docCount: state.caseDetail.documentCount,
  loadedQueue: state.queue.loadedQueue,
  task: state.caseDetail.activeTask
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  checkoutStagedAppeal,
  clearActiveCaseAndTask,
  pushBreadcrumb,
  resetBreadcrumbs,
  resetDecisionOptions,
  setActiveCase,
  setActiveTask,
  setCaseReviewActionType,
  setDocumentCount,
  stageAppeal
}, dispatch);

export default withRouter(connect(mapStateToProps, mapDispatchToProps)(QueueDetailView));
