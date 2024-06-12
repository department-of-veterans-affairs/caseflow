import update from 'immutability-helper';
import * as Constants from '../constants';
import { orderBy } from 'lodash';

export const mapDataToInitialState = function() {
  return {
    loading: true,
  };
};

export const intakeManagerReducers = (state = mapDataToInitialState(), action = {}) => {
  switch (action.type) {
  case Constants.POPULATE_FLAGGED_FOR_REVIEW:
    return update(state, {
      loading: { $set: false },
    });
  default: return state;
  }
};
