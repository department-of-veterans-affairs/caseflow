import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { ACTIONS } from './constants';
import _ from 'lodash';

export const initialState = {
  loadedQueue: {
    appeals: [],
    tasks: []
  },
  filterCriteria: {
    searchQuery: ''
  }
};

const mapArrayToObjectById = (collection, attrs) => _(collection).
  map((item) => ([
    item.id, _.extend({}, item, attrs)
  ])).
  fromPairs().
  value();

const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_QUEUE_DETAILS:
    return update(state, {
      loadedQueue: {
        appeals: {
          $set: mapArrayToObjectById(action.payload.appeals, { docCount: 0 })
        },
        tasks: {
          $set: mapArrayToObjectById(action.payload.tasks)
        }
      }
    });
  case ACTIONS.SET_APPEAL_DOC_COUNT:
    return update(state, {
      loadedQueue: {
        appeals: {
          [action.payload.appealId]: {
            $set: {
              docCount: action.payload.docCount
            }
          }
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
