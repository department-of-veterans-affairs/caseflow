import update from 'immutability-helper';
import * as Constants from '../constants';
import { sortBy } from 'lodash';

export const mapDataToInitialState = function() {
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
        $set: sortBy(action.payload.tasks, 'prepared_at')
      }
    });
  default: return state;
  }
};

