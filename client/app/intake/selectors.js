import { createSelector } from 'reselect';
import { RAMP_INTAKE_STATES } from './constants';
import _ from 'lodash';

const getRampElectionStatusSelector = ({ rampElection, intake }) => ({
  ..._.pick(rampElection, ['isComplete', 'isReviewed']),
  intakeId: intake.id
});

export const getRampElectionStatus = createSelector(
  [getRampElectionStatusSelector],
  (state) => {
    if (state.isComplete) {
      return RAMP_INTAKE_STATES.COMPLETED;
    } else if (state.isReviewed) {
      return RAMP_INTAKE_STATES.REVIEWED;
    } else if (state.intakeId) {
      return RAMP_INTAKE_STATES.STARTED;
    }

    return RAMP_INTAKE_STATES.NONE;
  }
);
