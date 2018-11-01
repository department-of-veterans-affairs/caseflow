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

import {
  newTasksByAssigneeCssIdSelector,
  pendingTasksByAssigneeCssIdSelector,
  onHoldTasksByAssigneeCssIdSelector,
  completeTasksByAssigneeCssIdSelector,
  tasksWithAppealSelector
} from './selectors';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

class OrganizationQueue extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
  }

  changeTab = (tabNumber) => {
    this.setState({
      // DO SOMETHING
    });
  }

  render = () => {
    const noTasks = !_.size(this.props.tasks);

    debugger;
    // this.props.tasks[0].status === 'assigned'

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

    const assignedTasks = _.filter(this.props.tasks, (task) => {
      return task.status === 'assigned';
    });

    const newTasks = _.filter(this.props.tasks, (task) => {
      return task.status === 'new';
    });

    const tabs = [
      {
        label: sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_UNASSIGNED_TAB_TITLE, newTasks.length),
        page: <UnassignedTasksTab />
      },
      {
        label: sprintf(COPY.ORGANIZATIONAL_QUEUE_PAGE_ASSIGNED_TAB_TITLE, assignedTasks.length),
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
        <TabWindow name="tasks-"
          tabs={tabs} 
          onChange={this.changeTab}
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
  (state: State) => ({ tasks: newTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysWaiting
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const AssignedTasksTab = connect(
  (state: State) => ({ tasks: pendingTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysOnHold
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });

const CompletedTasksTab = connect(
  (state: State) => ({ tasks: pendingTasksByAssigneeCssIdSelector(state) }))(
  (props: { tasks: Array<TaskWithAppeal> }) => {
    return <React.Fragment>
      <TaskTable
        includeDetailsLink
        includeTask
        includeType
        includeDocketNumber
        includeDaysOnHold
        includeReaderLink
        tasks={props.tasks}
      />
    </React.Fragment>;
  });