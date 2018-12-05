// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import QueueSelectorDropdown from './components/QueueSelectorDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../components/Alert';

import {
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

import type { TaskWithAppeal } from './types/models';

type Params = {||};

const containerStyles = css({
  position: 'relative'
});

type Props = Params & {|
  tasks: Array<TaskWithAppeal>,
  workableTasks: Array<TaskWithAppeal>,
  onHoldTasks: Array<TaskWithAppeal>,
  completedTasks: Array<TaskWithAppeal>,
  organizations: Array<Object>,
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

    if (_.some(
      [...this.props.workableTasks, ...this.props.onHoldTasks, ...this.props.completedTasks],
      (task) => !task.taskId)) {
      this.props.showErrorMessage({
        title: COPY.TASKS_NEED_ASSIGNMENT_ERROR_TITLE,
        detail: COPY.TASKS_NEED_ASSIGNMENT_ERROR_MESSAGE
      });
    }
  };

  render = () => {
    const { messages, organizations } = this.props;
    const noOpenTasks = !_.size([...this.props.workableTasks, ...this.props.onHoldTasks]);
    const noCasesMessage = noOpenTasks ?
      <p>
        {COPY.NO_CASES_IN_QUEUE_MESSAGE}
        <b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p> : '';

    const tabs = [
      {
        label: sprintf(
          COPY.QUEUE_PAGE_ASSIGNED_TAB_TITLE,
          this.props.workableTasks.length),
        page: <TaskTableTab
          description={COPY.ATTORNEY_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION}
          tasks={this.props.workableTasks}
        />
      },
      {
        label: sprintf(
          COPY.QUEUE_PAGE_ON_HOLD_TAB_TITLE,
          this.props.onHoldTasks.length),
        page: <TaskTableTab
          description={COPY.ATTORNEY_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}
          tasks={this.props.onHoldTasks}
        />
      },
      {
        label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <TaskTableTab
          description={COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}
          tasks={this.props.completedTasks}
        />
      }
    ];

    return <AppSegment filledBackground styling={containerStyles}>
      <h1 {...fullWidth}>{COPY.ATTORNEY_QUEUE_TABLE_TITLE}</h1>
      <QueueSelectorDropdown organizations={organizations} />
      {messages.error && <Alert type="error" title={messages.error.title}>
        {messages.error.detail}
      </Alert>}
      {messages.success && <Alert type="success" title={messages.success.title}>
        {messages.success.detail || COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
      </Alert>}
      {noCasesMessage}
      <TabWindow name="tasks-attorney-list" tabs={tabs} />
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
      messages,
      organizations
    }
  } = state;

  return ({
    workableTasks: workableTasksByAssigneeCssIdSelector(state),
    onHoldTasks: onHoldTasksByAssigneeCssIdSelector(state),
    completedTasks: completeTasksByAssigneeCssIdSelector(state),
    messages,
    organizations,
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

const TaskTableTab = ({ description, tasks }) => <React.Fragment>
  <p className="cf-margin-top-0" >{description}</p>
  <TaskTable
    includeDetailsLink
    includeType
    includeDocketNumber
    includeIssueCount
    includeDueDate
    includeReaderLink
    requireDasRecord
    tasks={tasks}
  />
</React.Fragment>;
