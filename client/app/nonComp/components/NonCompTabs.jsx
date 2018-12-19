import React from 'react';
import { connect } from 'react-redux';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import TabWindow from '../../components/TabWindow';
import { TaskTableUnconnected } from '../../queue/components/TaskTable';

class NonCompTabsUnconnected extends React.PureComponent {
  render = () => {
    const tabs = [{
      label: 'In progress tasks',
      page: <TaskTableTab
        description="In progress"
        tasks={this.props.inProgressTasks} />
    }, {
      label: 'Completed tasks',
      page: <TaskTableTab
        description="Completed"
        tasks={this.props.completedTasks} />
    }];

    return <TabWindow
      name="tasks-organization-queue"
      tabs={tabs}
    />;
  }
}

const claimantColumn = () => {
  return {
    header: 'Claimant',
    valueFunction: (task) => {
      return <Link to={`/queue/${task.type}/${task.id}`}>{task.claimant}</Link>;
    },
    getSortValue: (task) => task.claimant
  };
};

const veteranSsnColumn = () => {
  return {
    header: 'Veteran SSN',
    valueFunction: (task) => task.veteranSSN,
    getSortValue: (task) => task.veteranSSN
  };
};

const appealTypeColumn = () => {
  return {
    header: 'Type',
    valueFunction: (task) => task.type,
    getSortValue: (task) => task.type,
    // order determines where this column displays
    // make it 100 so this column is always last
    order: 100
  };
};

const TaskTableTab = ({ description, tasks }) => <React.Fragment>
  <p className="cf-margin-top-0">{description}</p>
  <TaskTableUnconnected
    getKeyForRow={(row, object) => object.id}
    customColumns={[claimantColumn(), veteranSsnColumn(), appealTypeColumn()]}
    includeIssueCount
    includeDaysWaiting
    tasks={tasks}
  />
</React.Fragment>;

const NonCompTabs = connect(
  (state) => ({
    inProgressTasks: state.inProgressTasks,
    completedTasks: state.completedTasks
  })
)(NonCompTabsUnconnected);

export default NonCompTabs;
