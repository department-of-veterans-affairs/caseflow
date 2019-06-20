import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import BulkAssignButton from './components/BulkAssignButton';
import TabWindow from '../components/TabWindow';
import TaskTable, { docketNumberColumn, hearingBadgeColumn, detailsColumn,
  taskColumn, regionalOfficeColumn, issueCountColumn, typeColumn,
  assignedToColumn, daysWaitingColumn, readerLinkColumn } from './components/TaskTable';
import QueueOrganizationDropdown from './components/QueueOrganizationDropdown';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  getUnassignedOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getCompletedOrganizationalTasks,
  trackingTasksForOrganization
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { fullWidth } from './constants';
import COPY from '../../COPY.json';
import Alert from '../components/Alert';

const containerStyles = css({
  position: 'relative'
});

const alertStyling = css({
  marginBottom: '1.5em'
});

const includeTrackingTasksTab = (organizationIsVso) => organizationIsVso;

const allowBulkAssign = (organizationName) => (organizationName === 'Hearings Management');

const showRegionalOfficeInQueue = (organizationName) =>
  (organizationName === 'Hearings Management' || organizationName === 'Hearing Admin');

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  // To load the contents of the page:
  // tasks = request to /tasks?tab={config.name}

  queueConfig = () => {
    const config = {
      table_title: sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName),
      organizations: this.props.organizations,
      active_tab_index: includeTrackingTasksTab(this.props.organizationIsVso) ? 1 : 0,
      tabs: [
        // Unassigned Tasks Tab
        {
          tasks: this.props.unassignedTasks,
          label: sprintf(
            COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
          description:
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName),
          organizationName: this.props.organizationName,
          userRole: this.props.userRole,
          allow_bulk_assign: allowBulkAssign(this.props.organizationName),
          columns: _.compact([
            'hearingBadgeColumn',
            'detailsColumn',
            'taskColumn',
            showRegionalOfficeInQueue(this.props.organizationName) ? 'regionalOfficeColumn' : null,
            'typeColumn',
            'docketNumberColumn',
            'daysWaitingColumn',
            'readerLinkColumn'
          ])
        },
        // Assigned Tasks tab
        {
          tasks: this.props.assignedTasks,
          label: sprintf(
            COPY.QUEUE_PAGE_ASSIGNED_TAB_TITLE, this.props.assignedTasks.length),
          description:
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName),
          organizationName: this.props.organizationName,
          userRole: this.props.userRole,
          columns: _.compact([
            'hearingBadgeColumn',
            'detailsColumn',
            'taskColumn',
            showRegionalOfficeInQueue(this.props.organizationName) ? 'regionalOfficeColumn' : null,
            'typeColumn',
            'assignedToColumn',
            'docketNumberColumn',
            'daysWaitingColumn'
          ])
        },
        // Completed Tasks tab
        {
          tasks: this.props.completedTasks,
          label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
          description: sprintf(COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION,
            this.props.organizationName),
          organizationName: this.props.organizationName,
          userRole: this.props.userRole,
          columns: _.compact([
            'hearingBadgeColumn',
            'detailsColumn',
            'taskColumn',
            showRegionalOfficeInQueue(this.props.organizationName) ? 'regionalOfficeColumn' : null,
            'typeColumn',
            'assignedToColumn',
            'docketNumberColumn',
            'daysWaitingColumn'
          ])
        }
      ]
    };

    // Tracking Task tab - when organization is a VSO
    if (includeTrackingTasksTab(this.props.organizationIsVso)) {
      config.tabs.unshift({
        tasks: this.props.trackingTasks,
        label: COPY.ALL_CASES_QUEUE_TABLE_TAB_TITLE,
        description: sprintf(COPY.ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, this.props.organizationName),
        userRole: this.props.userRole,
        columns: [
          'detailsColumn',
          'issueCountColumn',
          'typeColumn',
          'docketNumberColumn'
        ]
      });
    }

    return config;
  }

  createColumnObject = (column, config) => {
    const functionForColumn = {
      hearingBadgeColumn: hearingBadgeColumn(config.tasks),
      detailsColumn: detailsColumn(config.tasks, false, config.userRole),
      taskColumn: taskColumn(config.tasks),
      regionalOfficeColumn: regionalOfficeColumn(config.tasks),
      typeColumn: typeColumn(config.tasks, false),
      assignedToColumn: assignedToColumn(config.tasks),
      docketNumberColumn: docketNumberColumn(config.tasks, false),
      daysWaitingColumn: daysWaitingColumn(false),
      readerLinkColumn: readerLinkColumn(false, true),
      issueCountColumn: issueCountColumn(false)
    };

    return functionForColumn[column];
  }

  columnsFromConfig = (tabConfig) => {
    return tabConfig.columns.map((column) => {
      return this.createColumnObject(column, tabConfig);
    });
  }

  taskTableTabFactory = (tabConfig) => {
    const { tasks, label, description } = tabConfig;

    const cols = this.columnsFromConfig(tabConfig);

    return {
      label,
      page: <React.Fragment>
        <p className="cf-margin-top-0">{description}</p>
        { tabConfig.allow_bulk_assign && <BulkAssignButton /> }
        <TaskTable
          customColumns={cols}
          tasks={tasks}
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
      <QueueOrganizationDropdown organizations={config.organizations} />

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
    trackingTasks: trackingTasksForOrganization(state)
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);
