import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { ACTIONS } from './constants';
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';
import { combineReducers } from 'redux';

export const initialState = {
  loadedQueue: {
    appeals: [],
    tasks: []
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
  case ACTIONS.SET_APPEAL_DOC_COUNT:
    return update(state, {
      loadedQueue: {
        appeals: {
          [action.payload.appealId]: {
            docCount: {
              $set: action.payload.docCount
            }
          }
        }
      }
    });
  default:
    return state;
  }
};

const rootReducer = combineReducers({
  queue: workQueueReducer,
  caseSelect: caseSelectReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
