import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { reassignTasksToUser } from './QueueActions';
import { sortTasks } from './utils';
import AssignWidget from './components/AssignWidget';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';

class AssignedCasesPage extends React.PureComponent {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidUpdate = (prevProps) => {
    const { attorneyId: prevAttorneyId } = prevProps.match.params;
    const { attorneyId } = this.props.match.params;

    if (attorneyId !== prevAttorneyId) {
      this.props.resetSuccessMessages();
      this.props.resetErrorMessages();
    }
  }

  render = () => {
    const props = this.props;
    const {
      match, attorneysOfJudge, tasksAndAppealsOfAttorney, tasks, featureToggles
    } = props;
    const { attorneyId } = match.params;

    if (!(attorneyId in tasksAndAppealsOfAttorney) || tasksAndAppealsOfAttorney[attorneyId].state === 'LOADING') {
      return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
    }

    if (tasksAndAppealsOfAttorney[attorneyId].state === 'FAILED') {
      const { error } = tasksAndAppealsOfAttorney[attorneyId];

      if (!error.response) {
        return <StatusMessage title="Timeout">Error fetching cases</StatusMessage>;
      }

      return <StatusMessage title={error.response.statusText}>Error fetching cases</StatusMessage>;
    }

    const attorneyName = attorneysOfJudge.filter((attorney) => attorney.id.toString() === attorneyId)[0].full_name;
    const { tasks: taskIdsOfAttorney, appeals } = tasksAndAppealsOfAttorney[attorneyId].data;
    const tasksOfAttorney = {};

    for (const taskId of Object.keys(taskIdsOfAttorney)) {
      tasksOfAttorney[taskId] = tasks[taskId];
    }

    return <React.Fragment>
      <h2>{attorneyName}'s Cases</h2>
      {featureToggles.judge_assign_cases &&
        <AssignWidget
          previousAssigneeId={attorneyId}
          onTaskAssignment={(params) => props.reassignTasksToUser(params)} />}
      <JudgeAssignTaskTable
        tasksAndAppeals={
          sortTasks({
            tasks: tasksOfAttorney,
            appeals
          }).
            map((task) => ({
              task,
              appeal: appeals[task.vacolsId] }))
        }
        userId={attorneyId} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => {
  const { tasksAndAppealsOfAttorney, attorneysOfJudge, tasks } = state.queue;
  const { featureToggles } = state.ui;

  return { tasksAndAppealsOfAttorney,
    attorneysOfJudge,
    tasks,
    featureToggles };
};

export default connect(
  mapStateToProps,
  (dispatch) => (bindActionCreators({
    reassignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch)))(AssignedCasesPage);
