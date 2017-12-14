import { createSelector } from 'reselect';
import { RAMP_INTAKE_STATES } from '../constants';
import _ from 'lodash';

export const getRampElectionStatus = createSelector(
  [_.identity],
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
