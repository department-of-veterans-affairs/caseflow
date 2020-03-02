import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import TabWindow from '../components/TabWindow';
import QueueTable from './QueueTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import { docketNumberColumn, hearingBadgeColumn, detailsColumn, taskColumn, typeColumn, daysWaitingColumn,
  readerLinkColumnWithNewDocsIcon, issueCountColumn } from './components/TaskTableColumns';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../components/Alert';

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
import COPY from '../../COPY';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';

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
      [...this.props.assignedTasks, ...this.props.onHoldTasks, ...this.props.completedTasks],
      (task) => !task.taskId)) {
      this.props.showErrorMessage({
        title: COPY.TASKS_NEED_ASSIGNMENT_ERROR_TITLE,
        detail: COPY.TASKS_NEED_ASSIGNMENT_ERROR_MESSAGE
      });
    }
  };

  tasksForTab = (tabName) => {
    const mapper = {
      [QUEUE_CONFIG.INDIVIDUALLY_ASSIGNED_TASKS_TAB_NAME]: this.props.assignedTasks,
      [QUEUE_CONFIG.INDIVIDUALLY_ON_HOLD_TASKS_TAB_NAME]: this.props.onHoldTasks,
      [QUEUE_CONFIG.INDIVIDUALLY_COMPLETED_TASKS_TAB_NAME]: this.props.completedTasks
    };

    return mapper[tabName];
  }

  createColumnObject = (column, config, tasks) => {
    const functionForColumn = {
      [QUEUE_CONFIG.COLUMNS.HEARING_BADGE.name]: hearingBadgeColumn(tasks),
      [QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]: detailsColumn(tasks, false, config.userRole),
      [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, false),
      [QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]: typeColumn(tasks, false, false),
      [QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name]: docketNumberColumn(tasks, false, false),
      [QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name]: issueCountColumn(true),
      [QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]: daysWaitingColumn(false),
      [QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.name]: readerLinkColumnWithNewDocsIcon(true)
    };

    return functionForColumn[column.name];
  }

  columnsFromConfig = (config, tabConfig, tasks) =>
    (tabConfig.columns || []).map((column) => this.createColumnObject(column, config, tasks));

  taskTableTabFactory = (tabConfig, config) => {
    const tasks = this.tasksForTab(tabConfig.name);

    return {
      label: sprintf(tabConfig.label, tasks.length),
      page: <React.Fragment>
        <p className="cf-margin-top-0">{tabConfig.description}</p>
        <QueueTable
          key={tabConfig.name}
          columns={this.columnsFromConfig(config, tabConfig, tasks)}
          rowObjects={tasks}
          getKeyForRow={(_rowNumber, task) => task.uniqueId}
          enablePagination
        />
      </React.Fragment>
    };
  }

  tabsFromConfig = (config) => (config.tabs || []).map((tabConfig) => this.taskTableTabFactory(tabConfig, config));

  makeQueueComponents = (config) => <React.Fragment>
    <h1 {...fullWidth}>{config.table_title}</h1>
    <QueueOrganizationDropdown organizations={this.props.organizations} />
    <TabWindow name="tasks-tabwindow" tabs={this.tabsFromConfig(config)} />
  </React.Fragment>;

  render = () => {
    const { error, success } = this.props;
    const noOpenTasks = !_.size([...this.props.assignedTasks, ...this.props.onHoldTasks]);
    const noCasesMessage = noOpenTasks ?
      <p>
        {COPY.NO_CASES_IN_QUEUE_MESSAGE}
        <b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p> : '';

    return <AppSegment filledBackground styling={containerStyles}>
      {error && <Alert type="error" title={error.title}>
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success.title}>
        {success.detail || COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
      </Alert>}
      {noCasesMessage}
      {this.makeQueueComponents(this.props.queueConfig)}
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
    assignedTasks: workableTasksByAssigneeCssIdSelector(state),
    onHoldTasks: onHoldTasksForAttorney(state),
    completedTasks: completeTasksByAssigneeCssIdSelector(state),
    queueConfig: state.queue.queueConfig,
    success: messages.success,
    error: messages.error,
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

AttorneyTaskListView.propTypes = {
  assignedTasks: PropTypes.array,
  clearCaseSelectSearch: PropTypes.func,
  completedTasks: PropTypes.array,
  hideSuccessMessage: PropTypes.func,
  resetSaveState: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  showErrorMessage: PropTypes.func,
  onHoldTasks: PropTypes.array,
  organizations: PropTypes.array,
  queueConfig: PropTypes.object,
  success: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  })
};
