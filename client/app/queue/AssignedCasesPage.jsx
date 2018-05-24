import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { setSelectionOfTaskOfUser } from './QueueActions';
import { sortTasks } from './utils';

const AssignedCasesPage = (props) => {
  const {
    match, attorneysOfJudge, tasksAndAppealsOfAttorney
  } = props;
  const { attorneyId } = match.params;

  if (!(attorneyId in tasksAndAppealsOfAttorney) || tasksAndAppealsOfAttorney[attorneyId].state === 'LOADING') {
    return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
  }

  if (tasksAndAppealsOfAttorney[attorneyId].state === 'FAILED') {
    const { error } = tasksAndAppealsOfAttorney[attorneyId];

    return <StatusMessage title={error.response.statusText}>Error fetching cases</StatusMessage>;
  }

  const attorneyName = attorneysOfJudge.filter((attorney) => attorney.id.toString() === attorneyId)[0].full_name;
  const { tasks, appeals } = tasksAndAppealsOfAttorney[attorneyId].data;

  return <React.Fragment>
    <h2>{attorneyName}'s Cases</h2>
    <JudgeAssignTaskTable
      tasksAndAppeals={
        sortTasks({
          tasks,
          appeals
        }).
          map((task) => ({
            task,
            appeal: appeals[task.vacolsId] }))
      }
      userId={attorneyId} />
  </React.Fragment>;
};

export default connect(
  (state) => _.pick(state.queue, 'tasksAndAppealsOfAttorney', 'attorneysOfJudge'),
  (dispatch) => (bindActionCreators({ setSelectionOfTaskOfUser }, dispatch)))(AssignedCasesPage);
