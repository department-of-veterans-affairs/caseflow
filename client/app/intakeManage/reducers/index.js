import update from 'immutability-helper';
import * as Constants from '../constants';
import _ from 'lodash';

export const mapDataToInitialState = function() {
  return {
    loading: true,
    intakesForReview: {}
  };
};

export const manageIntakeReducers = (state = mapDataToInitialState(), action = {}) => {
  switch (action.type) {
  case Constants.POPULATE_INTAKES_FOR_REVIEW:
    return update(state, {
      loading: { $set: false },
      intakesForReview: {
        $set: _(action.payload.intakes).
          sortBy('prepared_at').
          value()
      }
    });
  default: return state;
  }
};
