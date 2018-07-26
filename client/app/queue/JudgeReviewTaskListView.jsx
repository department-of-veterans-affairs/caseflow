import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';

import StatusMessage from '../components/StatusMessage';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../components/Alert';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { judgeReviewAppealsSelector } from './selectors';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

class JudgeReviewTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  render = () => {
    const {
      userId,
      messages,
      appeals
    } = this.props;
    const reviewableCount = appeals.length;
    let tableContent;

    if (reviewableCount === 0) {
      tableContent = <StatusMessage title={COPY.NO_CASES_FOR_JUDGE_REVIEW_TITLE}>
        {COPY.NO_CASES_FOR_JUDGE_REVIEW_MESSAGE}
      </StatusMessage>;
    } else {
      tableContent = <TaskTable
        includeDetailsLink
        includeDocumentId
        includeType
        includeDocketNumber
        includeIssueCount
        includeDaysWaiting
        appeals={this.props.appeals}
      />;
    }

    return <AppSegment filledBackground>
      <h1 {...fullWidth}>{sprintf(COPY.JUDGE_CASE_REVIEW_TABLE_TITLE, reviewableCount)}</h1>
      <Link to={`/queue/${userId}/assign`}>{COPY.SWITCH_TO_ASSIGN_MODE_LINK_LABEL}</Link>
      {messages.error && <Alert type="error" title={messages.error.title}>
        {messages.error.detail}
      </Alert>}
      {messages.success && <Alert type="success" title={messages.success}>
        {COPY.JUDGE_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
      </Alert>}
      {tableContent}
    </AppSegment>;
  };
}

JudgeReviewTaskListView.propTypes = {
  appeals: PropTypes.array.isRequired
};

const mapStateToProps = (state) => {
  const {
    ui: {
      messages
    }
  } = state;

  return {
    appeals: judgeReviewAppealsSelector(state),
    messages
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeReviewTaskListView);
