import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import * as Constants from './actionTypes';

export const initialState = {
  loadedQueue: {
    appeals: [],
    tasks: []
  }
};

const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.RECEIVE_QUEUE_DETAILS:
    return update(state, {
      loadedQueue: {
        appeals: {
          $set: action.payload.appeals.data
        },
        tasks: {
          $set: action.payload.tasks.data
        }
      }
    });
  default:
    return state;
  }
};

export default timeFunction(
  workQueueReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
