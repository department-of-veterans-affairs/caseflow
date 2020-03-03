import React from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import { connect } from 'react-redux';

import QueueTable from './QueueTable';
import TabWindow from '../components/TabWindow';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import { completedToNameColumn, daysOnHoldColumn, daysWaitingColumn, detailsColumn, docketNumberColumn,
  hearingBadgeColumn, issueCountColumn, readerLinkColumn, readerLinkColumnWithNewDocsIcon, regionalOfficeColumn,
  taskColumn, taskCompletedDateColumn, typeColumn } from './components/TaskTableColumns';

import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import { fullWidth } from './constants';

/**
 * A component to create a queue table's tabs and columns from a queue config and the user's tasks
 * The required props are:
 * - @assignedTasks {array[object]} array of task objects to appear in the assigned tab
 * - @onHoldTasks {array[object]} array of task objects to appear in the on hold tab
 * - @completedTasks {array[object]} array of task objects to appear in the completed tab
 **/

class QueueTableBuilder extends React.PureComponent {

  tasksForTab = (tabName) => {
    const mapper = {
      [QUEUE_CONFIG.INDIVIDUALLY_ASSIGNED_TASKS_TAB_NAME]: this.props.assignedTasks,
      [QUEUE_CONFIG.INDIVIDUALLY_ON_HOLD_TASKS_TAB_NAME]: this.props.onHoldTasks,
      [QUEUE_CONFIG.INDIVIDUALLY_COMPLETED_TASKS_TAB_NAME]: this.props.completedTasks
    };

    return mapper[tabName];
  }

  createColumnObject = (column, config, tasks) => {
    const requireDasRecord = config.userRole === USER_ROLE_TYPES.attorney;
    const functionForColumn = {
      [QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]: typeColumn(tasks, false, requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]: detailsColumn(tasks, requireDasRecord, config.userRole),
      [QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]: daysOnHoldColumn(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]: daysWaitingColumn(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name]: docketNumberColumn(tasks, false, requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name]: readerLinkColumn(requireDasRecord, true),
      [QUEUE_CONFIG.COLUMNS.HEARING_BADGE.name]: hearingBadgeColumn(tasks),
      [QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name]: issueCountColumn(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.name]: readerLinkColumnWithNewDocsIcon(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name]: regionalOfficeColumn(tasks, false),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name]: completedToNameColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]: taskCompletedDateColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, false)
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

  render = () => {
    const { config } = this.props;

    return <React.Fragment>
      <h1 {...fullWidth}>{config.table_title}</h1>
      <QueueOrganizationDropdown organizations={this.props.organizations} />
      <TabWindow name="tasks-tabwindow" tabs={this.tabsFromConfig(config)} />
    </React.Fragment>;
  };
}

const mapStateToProps = (state) => {
  return ({
    config: state.queue.queueConfig,
    organizations: state.ui.organizations
  });
};

QueueTableBuilder.propTypes = {
  organizations: PropTypes.array,
  assignedTasks: PropTypes.array,
  onHoldTasks: PropTypes.array,
  completedTasks: PropTypes.array,
  config: PropTypes.shape({
    table_title: PropTypes.string
  })
};

export default (connect(mapStateToProps)(QueueTableBuilder));
