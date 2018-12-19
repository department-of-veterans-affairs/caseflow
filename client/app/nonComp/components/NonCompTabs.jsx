import TabWindow from '../../components/TabWindow';
import TaskTable from '../../queue/components/TaskTable';

class NonCompTabs extends React.PureComponent {
  render = () => {
    const tabs = [{
      label: 'In progress tasks',
      page: <TaskTableTab
        description="In progress"
        tasks={this.props.unassignedTasks}/>
    },{
      label: 'Completed tasks',
      page: <TaskTableTab
        description="Completed"
        tasks={this.props.completedTasks}/>
    }]
  }
}

const TaskTableTab = ({ description, tasks }) => <React.Fragment>
   <p className="cf-margin-top-0">{description}</p>
   <TaskTable
     // includeClaimantLink
     // includeClaimantSsn
     includeTask
     includeIssueCount
     includeDaysWaiting
     tasks={tasks}
   />
 </React.Fragment>;
