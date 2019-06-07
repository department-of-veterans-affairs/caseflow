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

// TODO: Is this worth it just because it is a handy alias? Yes
const includeTrackingTasksTab = (organizationIsVso) => organizationIsVso;

const allowBulkAssign = (organizationName) => (organizationName === 'Hearing Management');

const showRegionalOfficeInQueue = (organizationName) =>
  (organizationName === 'Hearing Management' || organizationName === 'Hearing Admin');






class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  columnsFromConfig = (columnStrings, organizationName) => {
    // UNASSIGNED

    // const requestedColumns = config.column;

    let columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
      userRole), taskColumn(tasks), typeColumn(tasks, false),
    docketNumberColumn(tasks, false), daysWaitingColumn(false),
    readerLinkColumn(false, true)];

    if (organizationName === 'Hearing Management' || organizationName === 'Hearing Admin') {
      columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
        userRole), taskColumn(tasks), regionalOfficeColumn(tasks),
      typeColumn(tasks, false), docketNumberColumn(tasks, false),
      daysWaitingColumn(false), readerLinkColumn(false, true)];
    }

    return columns;
  }

  tabFactory = (config) => {
    let tab;

    switch (config.TabType) {
      case COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE:
        tab = {
          label: sprintf(
            COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, config.tasks.length),
          page: <UnassignedTaskTableTab
            organizationName={config.organizationName}
            description={
              sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
                config.organizationName)}
            tasks={config.tasks}
          />
        }
        break;
      default:
        continue;

    return tab;
  }

  tabsFromConfig = (config) => {
    return config.tabs.map((tabConfig) => {
      return tabFactory(tabConfig)

      // return {
      //   label: sprintf(
      //     COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
      //   page: <UnassignedTaskTableTab
      //     organizationName={this.props.organizationName}
      //     description={
      //       sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
      //         this.props.organizationName)}
      //     tasks={this.props.unassignedTasks}
      //   />
      // };


      // <React.Fragment>
      //   <p className="cf-margin-top-0">{description}</p>
      //   { tabConfig.allow_bulk_assign && <BulkAssignButton /> }
      //   <TaskTable
      //     customColumns={this.columnsFromConfig(tabConfig.columns, config.organizationName)}
      //     tasks={tabConfig.tasks}
      //   />
      // </React.Fragment>;
    });


    // const tabs = [
    //   {
    //     label: sprintf(
    //       COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
    //     page: <UnassignedTaskTableTab
    //       organizationName={this.props.organizationName}
    //       description={
    //         sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
    //           this.props.organizationName)}
    //       tasks={this.props.unassignedTasks}
    //     />
    //   },


      // {
      //   label: sprintf(
      //     COPY.QUEUE_PAGE_ASSIGNED_TAB_TITLE, this.props.assignedTasks.length),
      //   page: <TaskTableWithUserColumnTab
      //     organizationName={this.props.organizationName}
      //     description={
      //       sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION,
      //         this.props.organizationName)}
      //     tasks={this.props.assignedTasks}
      //     userRole={this.props.userRole}
      //   />
      // },
      // {
      //   label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
      //   page: <TaskTableWithUserColumnTab
      //     organizationName={this.props.organizationName}
      //     description={
      //       sprintf(COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION,
      //         this.props.organizationName)}
      //     tasks={this.props.completedTasks}
      //     userRole={this.props.userRole}
      //   />
      // }
    // ];

    // return tabs;
  }

// THE BIG KAHUNA
  componentsFromConfig = (config) => {
    const tabs = this.tabsFromConfig(config);

    return <div>
      <h1 {...fullWidth}>{config.table_title}</h1>
      <QueueOrganizationDropdown organizations={config.organizations} />

      <TabWindow
        name="tasks-organization-queue"
        tabs={tabs}
        defaultPage={config.active_tab}
      />
    </div>;
  }

  // <TabWindow
  //   name="tasks-organization-queue"
  //   tabs={tabs}
  //   defaultPage={config.active_tab}
  // />

  // <QueueOrganizationDropdown organizations={this.props.organizations} />
  // <TabWindow
  //   name="tasks-organization-queue"
  //   tabs={tabs}
  //   defaultPage={config.active_tab}
  // />

  queueConfig = () => {
    return {
      table_title: sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName),
      organizations: this.props.organizations,

      active_tab: 0, // TODO: This needs to respond to whether we have the tracking tasks tab or not.
      organizationName: this.props.organizationName,
      tabs: [
        {
          tabType:COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
          tasks: this.props.unassignedTasks,
          organizationName: this.props.organizationName
          // label: sprintf(
          //   COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
          // page: <UnassignedTaskTableTab
          //   organizationName={this.props.organizationName}
          //   description={
          //     sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
          //       this.props.organizationName)}
          //   tasks={this.props.unassignedTasks}
          // />
        }
      ]






      // [
        // tracking tasks tab
        // {
        //   name: COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
        //   description: sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, this.props.organizationName),
        //   // Compact to account for the maybe absent regional office column
        //   label: sprintf(
        //     COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
        //   columns: _.compact([
        //     "hearingBadgeColumn",
        //     "detailsColumn",
        //     "taskColumn",
        //     showRegionalOfficeInQueue(this.props.organizationName) ? "regionalOfficeColumn" : null,
        //     "typeColumn",
        //     "docketNumberColumn",
        //     "daysWaitingColumn",
        //     "readerLinkColumn"
        //   ]),
        //   allow_bulk_assign: allowBulkAssign(this.props.organizationName),
        //   tasks: this.props.unassignedTasks,
        // }

        // unassigned tasks tab

        //
      // ]

    };
  }

  tabs: [
    // Tracking tasks tab.
    // Unassigned tasks tab.
    // {
    //   name: COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
    //   description: sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, this.props.organizationName),
    //   // Compact to account for the maybe absent regional office column
    //   columns: _.compact([
    //     "hearingBadgeColumn",
    //     "detailsColumn",
    //     "taskColumn",
    //     showRegionalOfficeInQueue(this.props.organizationName) ? "regionalOfficeColumn" : null,
    //     "typeColumn",
    //     "docketNumberColumn",
    //     "daysWaitingColumn",
    //     "readerLinkColumn"
    //   ]),
    //   allow_bulk_assign: allowBulkAssign(this.props.organizationName),
    //   tasks: this.props.unassignedTasks
    // },
    // Assigned tasks tab.
    // Completed tasks tab.
  ]

  render = () => {
    const { success, tasksAssignedByBulk } = this.props;
    const tabs = [
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
        page: <UnassignedTaskTableTab
          organizationName={this.props.organizationName}
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.unassignedTasks}
        />
      },
      {
        label: sprintf(
          COPY.QUEUE_PAGE_ASSIGNED_TAB_TITLE, this.props.assignedTasks.length),
        page: <TaskTableWithUserColumnTab
          organizationName={this.props.organizationName}
          description={
            sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.assignedTasks}
          userRole={this.props.userRole}
        />
      },
      {
        label: COPY.QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <TaskTableWithUserColumnTab
          organizationName={this.props.organizationName}
          description={
            sprintf(COPY.QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION,
              this.props.organizationName)}
          tasks={this.props.completedTasks}
          userRole={this.props.userRole}
        />
      }
    ];

    // Focus on the first tab in the list of tabs unless we have an "all cases" view, in which case the first tab will
    // be the "all cases" tab. In that case focus on the second tab which will be the first tab with workable tasks.
    let focusedTab = 0;

    if (this.props.organizationIsVso) {
      focusedTab = 1;
      tabs.unshift({
        label: COPY.ALL_CASES_QUEUE_TABLE_TAB_TITLE,
        page: <React.Fragment>
          <p className="cf-margin-top-0">
            {sprintf(COPY.ALL_CASES_QUEUE_TABLE_TAB_DESCRIPTION, this.props.organizationName)}
          </p>
          <TaskTable
            customColumns={[
              detailsColumn(this.props.trackingTasks, false, this.props.userRole),
              issueCountColumn(false),
              typeColumn(this.props.trackingTasks, false),
              docketNumberColumn(this.props.trackingTasks, false)
            ]}
            tasks={this.props.trackingTasks}
          />
        </React.Fragment>
      });
    }

    const body = this.componentsFromConfig(this.queueConfig());

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

// <div>
//   <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>
//   <QueueOrganizationDropdown organizations={this.props.organizations} />
//   <TabWindow
//     name="tasks-organization-queue"
//     tabs={tabs}
//     defaultPage={focusedTab}
//   />
// </div>

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

const UnassignedTaskTableTab = ({ description, tasks, organizationName, userRole }) => {
  let columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
    userRole), taskColumn(tasks), typeColumn(tasks, false),
  docketNumberColumn(tasks, false), daysWaitingColumn(false),
  readerLinkColumn(false, true)];

  if (organizationName === 'Hearing Management' || organizationName === 'Hearing Admin') {
    columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
      userRole), taskColumn(tasks), regionalOfficeColumn(tasks),
    typeColumn(tasks, false), docketNumberColumn(tasks, false),
    daysWaitingColumn(false), readerLinkColumn(false, true)];
  }

  return (<React.Fragment>
    <p className="cf-margin-top-0">{description}</p>
    { organizationName === 'Hearing Management' && <BulkAssignButton /> }
    <TaskTable
      customColumns={columns}
      tasks={tasks}
    />
  </React.Fragment>);
};

const TaskTableWithUserColumnTab = ({ description, tasks, organizationName, userRole }) => {
  let columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
    userRole), taskColumn(tasks), typeColumn(tasks, false),
  assignedToColumn(tasks), docketNumberColumn(tasks, false),
  daysWaitingColumn(false)];

  if (organizationName === 'Hearing Management' || organizationName === 'Hearing Admin') {
    columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
      userRole), taskColumn(tasks), regionalOfficeColumn(tasks),
    typeColumn(tasks, false), assignedToColumn(tasks),
    docketNumberColumn(tasks, false), daysWaitingColumn(false)];
  }

  return <React.Fragment>
    <p className="cf-margin-top-0">{description}</p>
    <TaskTable
      customColumns={columns}
      tasks={tasks}
    />
  </React.Fragment>;
};
