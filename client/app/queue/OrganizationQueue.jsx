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

  queueConfig = () => {
    return {
      table_title: sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName),
      organizations: this.props.organizations,
      active_tab: this.props.organizationIsVso ? 1 : 0, // TODO: This needs to respond to whether we have the tracking tasks tab or not. then it should be 1 -- this is if if () {
      organizationName: this.props.organizationName,
      tabs: [
        {
          tabTitle: COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
          label: sprintf(
              COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, this.props.unassignedTasks.length),
          tasks: this.props.unassignedTasks,
          organizationName: this.props.organizationName,
          userRole: this.props.userRole,
          showRegionalOffice: showRegionalOfficeInQueue(this.props.organizationName),
          allow_bulk_assign: allowBulkAssign(this.props.organizationName),
          tabType: COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
          columns: _.compact([
              "hearingBadgeColumn",
              "detailsColumn",
              "taskColumn",
              showRegionalOfficeInQueue(this.props.organizationName) ? "regionalOfficeColumn" : null,
              "typeColumn",
              "docketNumberColumn"
              // "daysWaitingColumn",
              // "readerLinkColumn"
            ])

        },

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

  // accepts column string, calls proper column objection creation function, returns it.
  createColumnObject = (column) => {
    console.log("-------------");
    console.dir(this.props.unassignedTasks);
    console.log(column);
    const functionForColumn = {
      hearingBadgeColumn: hearingBadgeColumn(this.props.unassignedTasks),
      detailsColumn: detailsColumn(this.props.unassignedTasks, false, this.props.userRole),
      taskColumn: taskColumn(this.props.unassignedTasks),
      regionalOfficeColumn: regionalOfficeColumn(this.props.unassignedTasks),
      typeColumn: typeColumn(this.props.unassignedTasks, false),
      docketNumberColumn: docketNumberColumn(this.props.unassignedTasks, false)

    };

    return functionForColumn[column];
  }

  //
  // columns = [
  //   hearingBadgeColumn(tasks),
  //   detailsColumn(tasks, false,
  //   userRole),
  //   taskColumn(tasks),
  //   regionalOfficeColumn(tasks),
  //   typeColumn(tasks, false),
  //   docketNumberColumn(tasks, false),
  //   daysWaitingColumn(false),
  //   readerLinkColumn(false, true)];

  // call all those pure column functions you made and
  // return them in an array that can be passed
  columnsFromConfig = (columnConfig) => {
    const customColumns = columnConfig.map((column) => {
      return this.createColumnObject(column);
    })

    console.log(customColumns);
    return customColumns
  }



  // const UnassignedTaskTableTab = ({ description, tasks, organizationName, userRole }) => {
  //   let columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
  //     userRole), taskColumn(tasks), typeColumn(tasks, false),
  //   docketNumberColumn(tasks, false), daysWaitingColumn(false),
  //   readerLinkColumn(false, true)];
  //
  //   if (organizationName === 'Hearing Management' || organizationName === 'Hearing Admin') {
  //     columns = [hearingBadgeColumn(tasks), detailsColumn(tasks, false,
  //       userRole), taskColumn(tasks), regionalOfficeColumn(tasks),
  //     typeColumn(tasks, false), docketNumberColumn(tasks, false),
  //     daysWaitingColumn(false), readerLinkColumn(false, true)];
  //   }
  //
  //   return (<React.Fragment>
  //     <p className="cf-margin-top-0">{description}</p>
  //     { organizationName === 'Hearing Management' && <BulkAssignButton /> }
  //     <TaskTable
  //       customColumns={columns}
  //       tasks={tasks}
  //     />
  //   </React.Fragment>);
  // };

  taskTableTabFactory = (tabConfig, config) => {
    // let tab;

    let { columns, tasks } = tabConfig;

    // feeds an array of strings identifying which columnFunctions to call.
    // returns an array of column objects
    const cols = this.columnsFromConfig(columns);

    return {
      label: 'lolol',
      page: <React.Fragment>
        <p className="cf-margin-top-0">{config.description}</p>
        <TaskTable
          customColumns={cols}
          tasks={tasks}
        />
        </React.Fragment>
    }
  }

    // switch (config.TabType) {
    //   case COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE:
    //     tab = {
    //       label: sprintf(
    //         COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, config.tasks.length),
    //       page:
    //       <UnassignedTaskTableTab
    //         organizationName={config.organizationName}
    //         description={
    //           sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION,
    //             config.organizationName)}
    //         tasks={config.tasks}
    //       />
    //     }
    //     break;
    //   default:
    //     continue;
    //
    // return tab;
  // }

  tabsFromConfig = (config) => {
    return config.tabs.map((tabConfig) => {
      return this.taskTableTabFactory(tabConfig, config)
    });
  }

// THE BIG KAHUNA
  makeQueueComponents = (config) => {

    // should return an array of React.Fragments that
    // contain TaskTableWithUserColumnTab
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

  // <div>
  //   <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>
  //   <QueueOrganizationDropdown organizations={this.props.organizations} />
  //   <TabWindow
  //     name="tasks-organization-queue"
  //     tabs={tabs}
  //     defaultPage={focusedTab}
  //   />
  // </div>


  // <QueueOrganizationDropdown organizations={this.props.organizations} />
  // <TabWindow
  //   name="tasks-organization-queue"
  //   tabs={tabs}
  //   defaultPage={config.active_tab}
  // />


  //
  // tabs: [
  //   // Tracking tasks tab.
  //   // Unassigned tasks tab.
  //   // {
  //   //   name: COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
  //   //   description: sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TASKS_DESCRIPTION, this.props.organizationName),
  //   //   // Compact to account for the maybe absent regional office column
  //   //   columns: _.compact([
  //   //     "hearingBadgeColumn",
  //   //     "detailsColumn",
  //   //     "taskColumn",
  //   //     showRegionalOfficeInQueue(this.props.organizationName) ? "regionalOfficeColumn" : null,
  //   //     "typeColumn",
  //   //     "docketNumberColumn",
  //   //     "daysWaitingColumn",
  //   //     "readerLinkColumn"
  //   //   ]),
  //   //   allow_bulk_assign: allowBulkAssign(this.props.organizationName),
  //   //   tasks: this.props.unassignedTasks
  //   // },
  //   // Assigned tasks tab.
  //   // Completed tasks tab.
  // ]

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
