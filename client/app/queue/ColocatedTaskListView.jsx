import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import QueueTable from './QueueTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import { docketNumberColumn, hearingBadgeColumn, detailsColumn, taskColumn, regionalOfficeColumn, typeColumn,
  daysWaitingColumn, daysOnHoldColumn, readerLinkColumn, completedToNameColumn, taskCompletedDateColumn,
  readerLinkColumnWithNewDocsIcon } from
  './components/TaskTableColumns';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  newTasksByAssigneeCssIdSelector,
  onHoldTasksByAssigneeCssIdSelector,
  completeTasksByAssigneeCssIdSelector
} from './selectors';
import { hideSuccessMessage } from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import {
  fullWidth,
  marginBottom
} from './constants';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';

import Alert from '../components/Alert';
import TabWindow from '../components/TabWindow';

const containerStyles = css({
  position: 'relative'
});

class ColocatedTaskListView extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  };

  componentWillUnmount = () => this.props.hideSuccessMessage();

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
      [QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name]: regionalOfficeColumn(tasks, false),
      [QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]: typeColumn(tasks, false, false),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name]: completedToNameColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]: taskCompletedDateColumn(),
      [QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name]: docketNumberColumn(tasks, false, false),
      [QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]: daysWaitingColumn(false),
      [QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]: daysOnHoldColumn(false),
      [QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name]: readerLinkColumn(false, true),
      [QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.name]: readerLinkColumnWithNewDocsIcon(false)
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
    const { success } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} styling={marginBottom(1)} />}
      {this.makeQueueComponents(this.props.queueConfig)}
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    organizations: state.ui.organizations,
    assignedTasks: newTasksByAssigneeCssIdSelector(state),
    onHoldTasks: onHoldTasksByAssigneeCssIdSelector(state),
    completedTasks: completeTasksByAssigneeCssIdSelector(state),
    queueConfig: state.queue.queueConfig
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseSelectSearch,
  hideSuccessMessage
}, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(ColocatedTaskListView));

ColocatedTaskListView.propTypes = {
  assignedTasks: PropTypes.array,
  clearCaseSelectSearch: PropTypes.func,
  completedTasks: PropTypes.array,
  hideSuccessMessage: PropTypes.func,
  onHoldTasks: PropTypes.array,
  organizations: PropTypes.array,
  queueConfig: PropTypes.object,
  success: PropTypes.object
};
