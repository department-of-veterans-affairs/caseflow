import React from 'react';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import { connect } from 'react-redux';
import querystring from 'querystring';


import BulkAssignButton from './components/BulkAssignButton';
import QueueTable from './QueueTable';
import TabWindow from '../components/TabWindow';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import { assignedToColumn, completedToNameColumn, daysOnHoldColumn, daysWaitingColumn, detailsColumn,
  docketNumberColumn, badgesColumn, issueCountColumn, readerLinkColumn, readerLinkColumnWithNewDocsIcon,
  regionalOfficeColumn, taskColumn, taskCompletedDateColumn, typeColumn } from './components/TaskTableColumns';
import { tasksWithAppealsFromRawTasks } from './utils';

import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';
import { fullWidth } from './constants';

/**
 * A component to create a queue table's tabs and columns from a queue config or the assignee's tasks
 * The props are:
 * - @assignedTasks {array[object]} array of task objects to appear in the assigned tab
 * - @onHoldTasks {array[object]} array of task objects to appear in the on hold tab
 * - @completedTasks {array[object]} array of task objects to appear in the completed tab
 **/

class QueueTableBuilder extends React.PureComponent {

  paginationOptions = () => querystring.parse(window.location.search.slice(1));

  calculateActiveTabIndex = (config) => {
    const tabNames = config.tabs.map((tab) => {
      return tab.name;
    });
    const activeTab = this.paginationOptions().tab || config.active_tab;
    const index = _.indexOf(tabNames, activeTab);

    return index === -1 ? 0 : index;
  }

  queueConfig = () => {
    const { config } = this.props;

    config.active_tab_index = this.calculateActiveTabIndex(config);

    return config;
  }

  tasksForTab = (tabName) => {
    const mapper = {
      [QUEUE_CONFIG.INDIVIDUALLY_ASSIGNED_TASKS_TAB_NAME]: this.props.assignedTasks,
      [QUEUE_CONFIG.INDIVIDUALLY_ON_HOLD_TASKS_TAB_NAME]: this.props.onHoldTasks,
      [QUEUE_CONFIG.INDIVIDUALLY_COMPLETED_TASKS_TAB_NAME]: this.props.completedTasks
    };

    return mapper[tabName];
  }

  filterValuesForColumn = (column) => column && column.filterable && column.filter_options;

  createColumnObject = (column, config, tasks) => {
    const { requireDasRecord } = this.props;
    const filterOptions = this.filterValuesForColumn(column);
    const functionForColumn = {
      [QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name]: typeColumn(tasks, filterOptions, requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.BADGES.name]: badgesColumn(tasks),
      [QUEUE_CONFIG.COLUMNS.CASE_DETAILS_LINK.name]: detailsColumn(tasks, requireDasRecord, config.userRole),
      [QUEUE_CONFIG.COLUMNS.DAYS_ON_HOLD.name]: daysOnHoldColumn(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.DAYS_WAITING.name]: daysWaitingColumn(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name]: docketNumberColumn(tasks, filterOptions, requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.DOCUMENT_COUNT_READER_LINK.name]: readerLinkColumn(requireDasRecord, true),
      [QUEUE_CONFIG.COLUMNS.ISSUE_COUNT.name]: issueCountColumn(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.READER_LINK_WITH_NEW_DOCS_ICON.name]: readerLinkColumnWithNewDocsIcon(requireDasRecord),
      [QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name]: regionalOfficeColumn(tasks, filterOptions),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name]: assignedToColumn(tasks, filterOptions),
      [QUEUE_CONFIG.COLUMNS.TASK_ASSIGNER.name]: completedToNameColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name]: taskCompletedDateColumn(),
      [QUEUE_CONFIG.COLUMNS.TASK_TYPE.name]: taskColumn(tasks, filterOptions)
    };

    return functionForColumn[column.name];
  }

  columnsFromConfig = (config, tabConfig, tasks) =>
    (tabConfig.columns || []).map((column) => this.createColumnObject(column, config, tasks));

  taskTableTabFactory = (tabConfig, config) => {
    const paginationOptions = this.paginationOptions();
    const tasks = config.use_task_pages_api ?
      tasksWithAppealsFromRawTasks(tabConfig.tasks) :
      this.tasksForTab(tabConfig.name);

    return {
      label: sprintf(tabConfig.label, tabConfig.total_task_count),
      page: <React.Fragment>
        <p className="cf-margin-top-0">{tabConfig.description}</p>
        { tabConfig.allow_bulk_assign && <BulkAssignButton /> }
        <QueueTable
          key={tabConfig.name}
          columns={this.columnsFromConfig(config, tabConfig, tasks)}
          rowObjects={tasks}
          getKeyForRow={(_rowNumber, task) => task.uniqueId}
          casesPerPage={config.tasks_per_page}
          numberOfPages={tabConfig.task_page_count}
          totalTaskCount={tabConfig.total_task_count}
          taskPagesApiEndpoint={tabConfig.task_page_endpoint_base_path}
          tabPaginationOptions={paginationOptions.tab === tabConfig.name && paginationOptions}
          useTaskPagesApi={config.use_task_pages_api}
          enablePagination
        />
      </React.Fragment>
    };
  }

  tabsFromConfig = (config) => (config.tabs || []).map((tabConfig) => this.taskTableTabFactory(tabConfig, config));

  render = () => {
    const config = this.queueConfig();

    return <React.Fragment>
      <h1 {...fullWidth}>{config.table_title}</h1>
      <QueueOrganizationDropdown organizations={this.props.organizations} />
      <TabWindow name="tasks-tabwindow" tabs={this.tabsFromConfig(config)} defaultPage={config.active_tab_index} />
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
    table_title: PropTypes.string,
    active_tab_index: PropTypes.number
  }),
  paginationOptions: PropTypes.object,
  requireDasRecord: PropTypes.bool
};

export default (connect(mapStateToProps)(QueueTableBuilder));
