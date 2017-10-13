import { createSelector } from 'reselect';

const getRampElection = (state) => state.rampElection;

export const getRampElectionStatus = createSelector(
  [getRampElection],
  (rampElection) => {
    if (rampElection.isComplete) {
      return 'completed';
    } else if (rampElection.isReviewed) {
      return 'reviewed';
    } else if (rampElection.intakeId) {
      return 'started';
    }

    return 'none';
  }
);
