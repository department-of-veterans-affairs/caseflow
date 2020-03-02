import React from 'react';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import { connect } from 'react-redux';

import QueueTable from './QueueTable';
import TabWindow from '../components/TabWindow';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import { docketNumberColumn, hearingBadgeColumn, detailsColumn, taskColumn, typeColumn, daysWaitingColumn,
  readerLinkColumnWithNewDocsIcon, issueCountColumn, regionalOfficeColumn, completedToNameColumn,
  taskCompletedDateColumn, daysOnHoldColumn, readerLinkColumn } from './components/TaskTableColumns';

import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';
import { fullWidth } from './constants';

/**
 * This component can be used to easily build tables.
 * The required props are:
 * - @assignedTasks {array[object]} array of task objects to appear in the assigned tab
 * - @onHoldTasks {array[object]} array of task objects to appear in the on hold tab
 * - @completedTasks {array[object]} array of task objects to appear in the completed tab
 * - @attorneyQueue {boolean} (might be able to use role) Whether or not this queue is for an attorney
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
    const { attorneyQueue } = this.props;
    const functionForColumn = {
      [QUEUE_CONFIG.COLUMNS.HEARING_BADGE.name]: hearingBadgeColumn(tasks),
      [QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]: detailsColumn(tasks, attorneyQueue, config.userRole),
      [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, false),
      [QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]: typeColumn(tasks, false, attorneyQueue),
      [QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name]: docketNumberColumn(tasks, false, attorneyQueue),
      [QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name]: issueCountColumn(attorneyQueue),
      [QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]: daysWaitingColumn(attorneyQueue),
      [QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.name]: readerLinkColumnWithNewDocsIcon(attorneyQueue),
      [QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name]: regionalOfficeColumn(tasks, false),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name]: completedToNameColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]: taskCompletedDateColumn(),
      [QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]: daysOnHoldColumn(attorneyQueue),
      [QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name]: readerLinkColumn(attorneyQueue, true)
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
  attorneyQueue: PropTypes.bool,
  config: PropTypes.shape({
    table_title: PropTypes.string
  })
};

export default (connect(mapStateToProps)(QueueTableBuilder));
