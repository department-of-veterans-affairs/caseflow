import { RAMP_INTAKE_STATES } from '../constants';

export const getRampElectionStatus = (rampElection) => {
  if (rampElection.isComplete) {
    return RAMP_INTAKE_STATES.COMPLETED;
  } else if (rampElection.isReviewed) {
    return RAMP_INTAKE_STATES.REVIEWED;
  } else if (rampElection.isStarted) {
    return RAMP_INTAKE_STATES.STARTED;
  }

  return RAMP_INTAKE_STATES.NONE;
};
