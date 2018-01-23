import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { ACTIONS } from './constants';

export const initialState = {
  loadedQueue: {
    appeals: [],
    tasks: []
  },
  filterCriteria: {
    searchQuery: ''
  }
};

const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_QUEUE_DETAILS:
    return update(state, {
      loadedQueue: {
        appeals: {
          $set: action.payload.appeals
        },
        tasks: {
          $set: action.payload.tasks
        }
      }
    });
  case ACTIONS.SET_SEARCH:
    return update(state, {
      filterCriteria: {
        searchQuery: {
          $set: action.payload.searchQuery
        }
      }
    });
  case ACTIONS.CLEAR_SEARCH:
    return update(state, {
      filterCriteria: {
        searchQuery: {
          $set: ''
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
