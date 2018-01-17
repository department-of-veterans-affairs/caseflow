import { combineReducers } from 'redux';
import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import * as Constants from './actionTypes';

const initialState = {};

const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
    default:
      return state;
  }
}

const rootReducer = combineReducers({
  workQueueReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
