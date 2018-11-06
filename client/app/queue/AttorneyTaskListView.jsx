// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import {
  tasksByAssigneeCssIdSelector,
  completeTasksByAssigneeCssIdSelector,
  onHoldTasksByAssigneeCssIdSelector,
  workableTasksByAssigneeCssIdSelector
} from './selectors';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
  showErrorMessage
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

import type { State } from './types/state';
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
    const tabs = [
      {
        label: sprintf(
          COPY.ATTORNEY_QUEUE_PAGE_ASSIGNED_TAB_TITLE,
          this.props.numberOfTasks.workable),
        page: <WorkableTasksTab />
      },
      {
        label: sprintf(
          COPY.ATTORNEY_QUEUE_PAGE_ON_HOLD_TAB_TITLE,
          this.props.numberOfTasks.onHold),
        page: <OnHoldTasksTab />
      },
      {
        label: COPY.ATTORNEY_QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <CompletedTasksTab />
      }
    ];

    return <AppSegment filledBackground>
      <div>
        <h1 {...fullWidth}>{COPY.ATTORNEY_QUEUE_TABLE_TITLE}</h1>
        {messages.error && <Alert type="error" title={messages.error.title}>
          {messages.error.detail}
        </Alert>}
        {messages.success && <Alert type="success" title={messages.success.title}>
          {messages.success.detail || COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
        </Alert>}
        <TabWindow
          name="tasks-attorney-list"
          tabs={tabs}
        />
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
    tasks: tasksByAssigneeCssIdSelector(state),
    numberOfTasks: {
      workable: workableTasksByAssigneeCssIdSelector(state).length,
      onHold: onHoldTasksByAssigneeCssIdSelector(state).length,
      completed: completeTasksByAssigneeCssIdSelector(state).length
    },
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

const WorkableTasksTab = connect(
  (state: State) => ({ tasks: workableTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.ATTORNEY_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const OnHoldTasksTab = connect(
  (state: State) => ({ tasks: onHoldTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.ATTORNEY_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const CompletedTasksTab = connect(
  (state: State) => ({ tasks: completeTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.ATTORNEY_QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}</p>
      <TaskTable includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });
