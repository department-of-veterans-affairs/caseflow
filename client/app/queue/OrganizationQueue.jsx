import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { createSelector } from 'reselect';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import {
  getNewOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getInProgressOrganizationalTasks,
  getCompletedOrganizationalTasks,
  tasksWithAppealSelector
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const noTasks = !_.size(this.props.tasks);

    debugger;
    
    const content = noTasks ?
      <h2>{COPY.NO_CASES_IN_QUEUE_MESSAGE}<Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link>.</h2> :
      <TaskTable
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDaysWaiting
        includeReaderLink
        tasks={this.props.tasks}
      />;

    const tabs = [
      {
        label: sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, /* TODO(joey) */ 0),
        page: <UnassignedTasksTab />
      },
      {
        label: sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE, /* TODO(joey) */ 0),
        page: <AssignedTasksTab />
      },
      {
        label: sprintf("In progress (%d)", /* TODO(joey) */ 0),
        page: <InProgressTasksTab />
      },
      {
        label: COPY.ORGANIZATIONAL_QUEUE_PAGE_COMPLETE_TAB_TITLE,
        page: <CompletedTasksTab />
      }
    ];

    return <AppSegment filledBackground>
      <div>
        <h1 {...fullWidth}>{sprintf(COPY.ORGANIZATION_QUEUE_TABLE_TITLE, this.props.organizationName)}</h1>
        <TabWindow 
          name="tasks-organization-queue"
          tabs={tabs} 
        />
        {content}
      </div>
    </AppSegment>;
  };
}

OrganizationQueue.propTypes = {
  tasks: PropTypes.array.isRequired
};

const mapStateToProps = (state) => {
  return ({
    tasks: tasksWithAppealSelector(state)
  });
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(OrganizationQueue);

const UnassignedTasksTab = connect(
  (state: State) => ({ tasks: getNewOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const AssignedTasksTab = connect(
  (state: State) => ({ tasks: getAssignedOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDaysOnHold
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const InProgressTasksTab = connect(
  (state: State) => ({ tasks: getInProgressOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    debugger;
    return <React.Fragment>
      <p>{COPY.COLOCATED_QUEUE_PAGE_ON_HOLD_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const CompletedTasksTab = connect(
  (state: State) => ({ tasks: getCompletedOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <p>{COPY.COLOCATED_QUEUE_PAGE_COMPLETE_TASKS_DESCRIPTION}</p>
      <TaskTable
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDaysOnHold
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });