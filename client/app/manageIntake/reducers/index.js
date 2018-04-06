import update from 'immutability-helper';
import * as Constants from '../constants';
import _ from 'lodash';

export const mapDataToInitialState = function() {
  return {
    loading: true,
    claimsForReview: {}
  };
};

export const manageIntakeReducers = (state = mapDataToInitialState(), action = {}) => {
  switch (action.type) {
  case Constants.POPULATE_CLAIMS_FOR_REVIEW:
    return update(state, {
      loading: { $set: false },
      claimsForReview: {
        $set: _(action.payload.claims).
          sortBy('prepared_at').
          value()
      }
    });
  default: return state;
  }
};
