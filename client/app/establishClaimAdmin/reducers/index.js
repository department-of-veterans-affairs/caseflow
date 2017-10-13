import update from 'immutability-helper';
import * as Constants from '../constants';
import _ from 'lodash';

export const mapDataToInitialState = function(state) {
  return {
    loading: true,
    stuckTasks: {}
  };
};

export const establishClaimAdminReducers = (state = mapDataToInitialState(), action = {}) => {
  switch (action.type) {
  case Constants.POPULATE_STUCK_TASKS:
    return update(state, {
      loading: { $set: false },
      stuckTasks: {
        $set: _(action.payload.tasks).
          sortBy('prepared_at').
          value()
      }
    });
  default: return state;
  }
};

