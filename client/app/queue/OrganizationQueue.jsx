import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import { sprintf } from 'sprintf-js';
import PropTypes from 'prop-types';

import BulkAssignButton from './components/BulkAssignButton';
import TabWindow from '../components/TabWindow';
import { docketNumberColumn, hearingBadgeColumn, detailsColumn, taskColumn, regionalOfficeColumn, issueCountColumn,
  typeColumn, assignedToColumn, daysWaitingColumn, daysOnHoldColumn, readerLinkColumn, completedToNameColumn } from
  './components/TaskTableColumns';

import QueueTable from './QueueTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import Alert from '../components/Alert';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  getUnassignedOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getCompletedOrganizationalTasks,
  trackingTasksForOrganization
} from './selectors';
import { tasksWithAppealsFromRawTasks } from './utils';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';
import QUEUE_CONFIG from '../../constants/QUEUE_CONFIG';

const containerStyles = css({
  position: 'relative'
});

const alertStyling = css({
  marginBottom: '1.5em'
});

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  calculateActiveTabIndex = (config) => {
    const tabNames = config.tabs.map((tab) => {
      return tab.name;
    });
    const { paginationOptions = {} } = this.props;
    const activeTab = paginationOptions.tab || config.active_tab;
    const index = _.indexOf(tabNames, activeTab);

    return index === -1 ? 0 : index;
  }

  queueConfig = () => {
    const config = this.props.queueConfig;

    config.active_tab_index = this.calculateActiveTabIndex(config);

    return config;
  }

  filterValuesForColumn = (column, config) =>
    config.use_task_pages_api && column && column.filterable && column.filter_options;

  createColumnObject = (column, config, tasks) => {
    const functionForColumn = {
      hearingBadgeColumn: hearingBadgeColumn(tasks),
      detailsColumn: detailsColumn(tasks, false, config.userRole),
      taskColumn: taskColumn(tasks, this.filterValuesForColumn(column, config)),
      regionalOfficeColumn: regionalOfficeColumn(tasks, this.filterValuesForColumn(column, config)),
      typeColumn: typeColumn(tasks, this.filterValuesForColumn(column, config), false),
      assignedToColumn: assignedToColumn(tasks, this.filterValuesForColumn(column, config)),
      completedToNameColumn: completedToNameColumn(),
      docketNumberColumn: docketNumberColumn(tasks, this.filterValuesForColumn(column, config), false),
      daysWaitingColumn: daysWaitingColumn(false),
      daysOnHoldColumn: daysOnHoldColumn(false),
      readerLinkColumn: readerLinkColumn(false, true),
      issueCountColumn: issueCountColumn(false)
    };

    return functionForColumn[column.name];
  }

  columnsFromConfig = (config, tabConfig, tasks) =>
    tabConfig.columns.map((column) => this.createColumnObject(column, config, tasks));

  tasksForTab = (tabName) => {
    const mapper = {
      [QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME]: this.props.unassignedTasks,
      [QUEUE_CONFIG.ASSIGNED_TASKS_TAB_NAME]: this.props.assignedTasks,
      [QUEUE_CONFIG.ON_HOLD_TASKS_TAB_NAME]: this.props.onHoldTasks,
      [QUEUE_CONFIG.COMPLETED_TASKS_TAB_NAME]: this.props.completedTasks,
      [QUEUE_CONFIG.TRACKING_TASKS_TAB_NAME]: this.props.trackingTasks
    };

    return mapper[tabName];
  }

  taskTableTabFactory = (tabConfig, config) => {
    const { paginationOptions = {} } = this.props;
    const tasks = config.use_task_pages_api ?
      tasksWithAppealsFromRawTasks(tabConfig.tasks) :
      this.tasksForTab(tabConfig.name);
    const cols = this.columnsFromConfig(config, tabConfig, tasks);
    const totalTaskCount = config.use_task_pages_api ? tabConfig.total_task_count : tasks.length;

    return {
      label: sprintf(tabConfig.label, totalTaskCount),
      page: <React.Fragment>
        <p className="cf-margin-top-0">{tabConfig.description}</p>
        { tabConfig.allow_bulk_assign && <BulkAssignButton /> }
        <QueueTable
          key={tabConfig.name}
          columns={cols}
          rowObjects={tasks}
          getKeyForRow={(_rowNumber, task) => task.uniqueId}
          useTaskPagesApi={config.use_task_pages_api}
          casesPerPage={config.tasks_per_page}
          numberOfPages={tabConfig.task_page_count}
          totalTaskCount={totalTaskCount}
          taskPagesApiEndpoint={tabConfig.task_page_endpoint_base_path}
          tabPaginationOptions={paginationOptions.tab === tabConfig.name && paginationOptions}
          enablePagination
        />
      </React.Fragment>
    };
  }

  tabsFromConfig = (config) => {
    return config.tabs.map((tabConfig) => {
      return this.taskTableTabFactory(tabConfig, config);
    });
  }

  makeQueueComponents = (config) => {
    return <div>
      <h1 {...fullWidth}>{config.table_title}</h1>
      <QueueOrganizationDropdown organizations={this.props.organizations} />

      <TabWindow
        name="tasks-organization-queue"
        tabs={this.tabsFromConfig(config)}
        defaultPage={config.active_tab_index}
      />
    </div>;
  }

  render = () => {
    const { success, tasksAssignedByBulk } = this.props;
    const body = this.makeQueueComponents(this.queueConfig());

    return <AppSegment filledBackground styling={containerStyles}>
      {success && <Alert type="success" title={success.title} message={success.detail} />}
      {tasksAssignedByBulk.assignedUser &&
        <Alert
          message="Please go to your individual queue to see your self assigned tasks"
          title={`You have bulk assigned
            ${tasksAssignedByBulk.numberOfTasks}
            ${tasksAssignedByBulk.taskType.replace(/([a-z])([A-Z])/g, '$1 $2')}
            task(s)`}
          type="success"
          styling={alertStyling} />
      }
      {body}
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  assignedTasks: PropTypes.array,
  clearCaseSelectSearch: PropTypes.func,
  completedTasks: PropTypes.array,
  onHoldTasks: PropTypes.array,
  organizations: PropTypes.array,
  queueConfig: PropTypes.object,
  success: PropTypes.object,
  tasksAssignedByBulk: PropTypes.object,
  trackingTasks: PropTypes.array,
  unassignedTasks: PropTypes.array,
  paginationOptions: PropTypes.object
};

const mapStateToProps = (state) => {
  const { success } = state.ui.messages;

  return {
    success,
    userRole: state.ui.userRole,
    organizationName: state.ui.activeOrganization.name,
    organizationIsVso: state.ui.activeOrganization.isVso,
    organizations: state.ui.organizations,
    tasksAssignedByBulk: state.queue.tasksAssignedByBulk,
    unassignedTasks: getUnassignedOrganizationalTasks(state),
    assignedTasks: getAssignedOrganizationalTasks(state),
    completedTasks: getCompletedOrganizationalTasks(state),
    trackingTasks: trackingTasksForOrganization(state),
    queueConfig: state.queue.queueConfig
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);
