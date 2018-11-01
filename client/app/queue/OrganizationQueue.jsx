import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import TabWindow from '../components/TabWindow';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import type { State } from './types/state';
import type { TaskWithAppeal } from './types/models';

import {
  getUnassignedOrganizationalTasks,
  getAssignedOrganizationalTasks,
  getCompletedOrganizationalTasks,
  tasksWithAppealSelector
} from './selectors';

import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import TASK_STATUSES from '../../constants/TASK_STATUSES.json';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

const countCasesByType = (tasks) => {
  const numberOfCases = {
    [TASK_STATUSES.assigned]: 0,
    [TASK_STATUSES.in_progress]: 0,
    [TASK_STATUSES.on_hold]: 0,
    [TASK_STATUSES.completed]: 0
  };

  return _.reduce(tasks, (cases, task) => {
    if (cases[task.status]) {
      cases[task.status] += 1;
    } else {
      cases[task.status] = 1;
    }

    return cases;
  }, numberOfCases);
};

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  render = () => {
    const numberOfCases = countCasesByType(this.props.tasks);
    const tabs = [
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE,
          numberOfCases.assigned + numberOfCases.in_progress),
        page: <UnassignedTasksTab />
      },
      {
        label: sprintf(
          COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE,
          numberOfCases.on_hold),
        page: <AssignedTasksTab />
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
  (state: State) => ({ tasks: getUnassignedOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    const noTasks = !_.size(props.tasks);

    const content = noTasks ?
      <p>{COPY.ORGANIZATIONAL_QUEUE_EMPTY_STATE_MESSAGE}
        <b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p> :
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />;

    return <React.Fragment>
      {content}
    </React.Fragment>;
  });

const AssignedTasksTab = connect(
  (state: State) => ({ tasks: getAssignedOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    const noTasks = !_.size(props.tasks);

    const content = noTasks ?
      <p>{COPY.ORGANIZATIONAL_QUEUE_EMPTY_STATE_MESSAGE}
        <b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p> :
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />;

    return <React.Fragment>
      {content}
    </React.Fragment>;
  });

const CompletedTasksTab = connect(
  (state: State) => ({ tasks: getCompletedOrganizationalTasks(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    const noTasks = !_.size(props.tasks);

    const content = noTasks ?
      <p>{COPY.ORGANIZATIONAL_QUEUE_EMPTY_STATE_MESSAGE}
        <b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p> :
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />;

    return <React.Fragment>
      {content}
    </React.Fragment>;
  });
