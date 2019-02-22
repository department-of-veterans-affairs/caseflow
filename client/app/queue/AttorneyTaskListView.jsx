import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../components/Alert';
import NewFileAll from './components/NewFileAll';

import {
  completeTasksByAssigneeCssIdSelector,
  workableTasksByAssigneeCssIdSelector,
  onHoldTasksForAttorney
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

const containerStyles = css({
  position: 'relative'
});

class AttorneyTaskListView extends React.PureComponent {
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
          includeNewDocsIcon={false}
          useOnHoldDate={false}
        />
      },
      {
        label: sprintf(
          COPY.QUEUE_PAGE_ON_HOLD_TAB_TITLE,
          this.props.onHoldTasks.length),
        page: <TaskTableTab
          description={COPY.ATTORNEY_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}
          tasks={this.props.onHoldTasks}
          includeNewDocsIcon
          useOnHoldDate
        />,
        indicator: <NewFileAll tasks={this.props.onHoldTasks} useOnHoldDate />
      },
      {
        label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <TaskTableTab
          description={COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}
          tasks={this.props.completedTasks}
          includeNewDocsIcon={false}
          useOnHoldDate={false}
        />
      }
    ];

    return <AppSegment filledBackground styling={containerStyles}>
      <h1 {...fullWidth}>{COPY.ATTORNEY_QUEUE_TABLE_TITLE}</h1>
      <QueueOrganizationDropdown organizations={organizations} />
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
    onHoldTasks: onHoldTasksForAttorney(state),
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

export default (connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskListView));

const TaskTableTab = ({ description, tasks, includeNewDocsIcon, useOnHoldDate }) => <React.Fragment>
  <p className="cf-margin-top-0" >{description}</p>
  <TaskTable
    includeHearingBadge
    includeDetailsLink
    includeType
    includeDocketNumber
    includeIssueCount
    includeDueDate
    includeReaderLink
    requireDasRecord
    tasks={tasks}
    includeNewDocsIcon={includeNewDocsIcon}
    useOnHoldDate={useOnHoldDate}
  />
</React.Fragment>;
