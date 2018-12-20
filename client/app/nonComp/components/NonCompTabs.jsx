import React from 'react';
import { connect } from 'react-redux';

import TabWindow from '../../components/TabWindow';
import { TaskTableUnconnected } from '../../queue/components/TaskTable';
import { claimantColumn, veteranSsnColumn, decisionReviewTypeColumn } from './TaskTableColumns';

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

const TaskTableTab = ({ description, tasks }) => <React.Fragment>
  <p className="cf-margin-top-0">{description}</p>
  <TaskTableUnconnected
    getKeyForRow={(row, object) => object.appeal.id}
    customColumns={[claimantColumn(), veteranSsnColumn(), decisionReviewTypeColumn()]}
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
