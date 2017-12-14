import { createSelector } from 'reselect';
import { RAMP_INTAKE_STATES } from '../constants';
import _ from 'lodash';

const getRelevantFields = (rampElection) => _.pick(rampElection, ['isComplete', 'isReviewed', 'intakeId']);

export const getRampElectionStatus = createSelector(
  [getRelevantFields],
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
