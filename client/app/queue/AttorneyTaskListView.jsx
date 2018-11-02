// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../components/Alert';

import { workableTasksByAssigneeCssIdSelector } from './selectors';
import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
  showErrorMessage
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

import type { TaskWithAppeal } from './types/models';

type Params = {||};

type Props = Params & {|
  tasks: Array<TaskWithAppeal>,
  messages: Object,
  resetSaveState: typeof resetSaveState,
  resetSuccessMessages: typeof resetSuccessMessages,
  resetErrorMessages: typeof resetErrorMessages,
  clearCaseSelectSearch: typeof clearCaseSelectSearch,
  showErrorMessage: typeof showErrorMessage,
|};

class AttorneyTaskListView extends React.PureComponent<Props> {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();

    if (_.some(this.props.tasks, (task) => !task.taskId)) {
      this.props.showErrorMessage({
        title: COPY.TASKS_NEED_ASSIGNMENT_ERROR_TITLE,
        detail: COPY.TASKS_NEED_ASSIGNMENT_ERROR_MESSAGE
      });
    }
  };

  render = () => {
    const { messages } = this.props;
    const noTasks = !_.size(this.props.tasks);

    const content = noTasks ?
      <p>{COPY.NO_CASES_IN_QUEUE_MESSAGE}<b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.</p> :
      <TaskTable
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDueDate
        includeReaderLink
        requireDasRecord
        tasks={this.props.tasks}
      />;

    return <AppSegment filledBackground>
      <div>
        <h1 {...fullWidth}>{COPY.ATTORNEY_QUEUE_TABLE_TITLE}</h1>
        {messages.error && <Alert type="error" title={messages.error.title}>
          {messages.error.detail}
        </Alert>}
        {messages.success && <Alert type="success" title={messages.success.title}>
          {messages.success.detail || COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
        </Alert>}
        {content}
      </div>
    </AppSegment>;
  }
}

const mapStateToProps = (state) => {
  const {
    queue: {
      stagedChanges: {
        taskDecision
      }
    },
    ui: {
      messages
    }
  } = state;

  return ({
    tasks: workableTasksByAssigneeCssIdSelector(state),
    messages,
    taskDecision
  });
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    showErrorMessage
  }, dispatch)
});

export default (connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskListView): React.ComponentType<Params>);
