import update from 'immutability-helper';
import * as Constants from '../constants';
import _ from 'lodash';

export const mapDataToInitialState = function() {
  return {
    loading: true,
    flaggedForReview: {}
  };
};

export const intakeManagerReducers = (state = mapDataToInitialState(), action = {}) => {
  switch (action.type) {
  case Constants.POPULATE_FLAGGED_FOR_REVIEW:
    return update(state, {
      loading: { $set: false },
      flaggedForReview: {
        $set: _(action.payload.intakes).
          orderBy('completed_at').
          value()
      }
    });
  default: return state;
  }
};
