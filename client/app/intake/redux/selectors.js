import { createSelector } from 'reselect';
import { RAMP_INTAKE_STATES } from '../constants';

const getRampElection = (state) => state.rampElection;

export const getRampElectionStatus = createSelector(
  [getRampElection],
  (rampElection) => {
    if (rampElection.isComplete) {
      return RAMP_INTAKE_STATES.COMPLETED;
    } else if (rampElection.isReviewed) {
      return RAMP_INTAKE_STATES.REVIEWED;
    } else if (rampElection.intakeId) {
      return RAMP_INTAKE_STATES.STARTED;
    }

    return RAMP_INTAKE_STATES.NONE;
  }
);
