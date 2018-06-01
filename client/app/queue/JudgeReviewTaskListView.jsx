// @flow
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import StatusMessage from '../components/StatusMessage';
import JudgeReviewTaskTable from './JudgeReviewTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../components/Alert';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';
import type { Tasks, LoadedQueueTasks, LoadedQueueAppeals } from './reducers';

class JudgeReviewTaskListView extends React.PureComponent<{
  loadedQueueTasks: LoadedQueueTasks,
  tasks: Tasks,
  appeals: LoadedQueueAppeals,
  messages: Object,
  resetSaveState: Function,
  resetSuccessMessages: Function,
  resetErrorMessages: Function,
  clearCaseSelectSearch: Function,
  userId: string
}> {
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
      loadedQueueTasks,
      userId,
      messages,
      tasks
    } = this.props;
    const reviewableCount = _.filter(loadedQueueTasks, (task) => tasks[task.id].attributes.task_type === 'Review').length;
    let tableContent;

    if (reviewableCount === 0) {
      tableContent = <StatusMessage title={COPY.NO_CASES_FOR_JUDGE_REVIEW_TITLE}>
        {COPY.NO_CASES_FOR_JUDGE_REVIEW_MESSAGE}
      </StatusMessage>;
    } else {
      tableContent = <JudgeReviewTaskTable />;
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
  loadedQueueTasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.queue.loadedQueue, 'appeals'),
  ..._.pick(state.queue, 'tasks'),
  ..._.pick(state.ui, 'messages'),
  loadedQueueTasks: state.queue.loadedQueue.tasks
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeReviewTaskListView);
