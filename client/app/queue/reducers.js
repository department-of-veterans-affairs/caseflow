import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import * as Constants from './actionTypes';

export const initialState = {
  loadedQueueId: null,
  didLoadQueueFail: false,
  loadedQueue: {
    appeals: [],
    tasks: []
  },
  showSearchBar: false,
  filterCriteria: {
    searchQuery: ''
  }
};

const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.RECEIVE_QUEUE_DETAILS:
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
  case Constants.SHOW_SEARCH_BAR:
    return update(state, { showSearchBar: { $set: true } });
  case Constants.HIDE_SEARCH_BAR:
    return update(state, { showSearchBar: { $set: false } });
  case Constants.SET_SEARCH:
    return update(state, {
      filterCriteria: {
        searchQuery: {
          $set: action.payload.searchQuery
        }
      }
    });
  case Constants.CLEAR_SEARCH:
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
