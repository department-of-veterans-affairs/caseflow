import { createSelector } from 'reselect';
import { RAMP_INTAKE_STATES } from './constants';
import _ from 'lodash';

const getIntakeDetailStatus = (intakeDetail) => {
  if (intakeDetail.isComplete) {
    return RAMP_INTAKE_STATES.COMPLETED;
  } else if (intakeDetail.isReviewed) {
    return RAMP_INTAKE_STATES.REVIEWED;
  } else if (intakeDetail.isStarted) {
    return RAMP_INTAKE_STATES.STARTED;
  }

  return null;
};

const getIntakeStatusSelector = ({ rampElection, rampRefiling }) => ({
  rampElection: _.pick(rampElection, ['isStarted', 'isReviewed', 'isComplete']),
  rampRefiling: _.pick(rampRefiling, ['isStarted', 'isReviewed', 'isComplete'])
});

export const getIntakeStatus = createSelector(
  [getIntakeStatusSelector],
  (state) => {
    // Only one intake detail should be started at a time,
    // so find that intake detail's status
    const status = _.reduce(state, (result, intakeDetail) => (
      result || getIntakeDetailStatus(intakeDetail)
    ), null);

    return status || RAMP_INTAKE_STATES.NONE;
  }
);
