import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { ACTIONS } from './constants';
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';
import { combineReducers } from 'redux';

export const initialState = {
  loadedQueue: {
    appeals: {},
    tasks: {},
    loadedUserId: null
  },
  taskDecision: {
    type: '',
    opts: {}
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
        },
        loadedUserId: {
          $set: action.payload.userId
        }
      }
    });
  case ACTIONS.SET_APPEAL_DOC_COUNT:
  case ACTIONS.LOAD_APPEAL_DOC_COUNT_FAILURE:
    return update(state, {
      loadedQueue: {
        appeals: {
          [action.payload.vacolsId]: {
            attributes: {
              docCount: {
                $set: action.payload.docCount
              }
            }
          }
        }
      }
    });
  case ACTIONS.SET_DECISION_TYPE:
    return update(state, {
      taskDecision: {
        type: { $set: action.payload.type }
      }
    })
  case ACTIONS.SET_DECISION_OPTIONS:
    return update(state, {
      taskDecision: {
        opts: { $merge: action.payload.opts }
      }
    })
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
