import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { ACTIONS } from './constants';
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';
import { combineReducers } from 'redux';
import _ from 'lodash';

export const initialState = {
  loadedQueue: {
    appeals: {},
    tasks: {},
    loadedUserId: null
  },
  taskDecision: {
    type: '',
    opts: {}
  },
  /**
   * `pendingChanges` is an object of appeals/tasks that have been modified since
   * loading from the server. When a user starts editing an appeal/task, we copy
   * it from `loadedQueue[obj.type]`. TBD: To commit the edits, we copy from
   * `pendingChanges` back into `loadedQueue`. To discard changes, we delete
   * from `pendingChanges`.
   */
  pendingChanges: {
    appeals: {},
    tasks: {}
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
  case ACTIONS.SET_REVIEW_ACTION_TYPE:
    return update(state, {
      taskDecision: {
        type: { $set: action.payload.type }
      }
    });
  case ACTIONS.SET_DECISION_OPTIONS:
    return update(state, {
      taskDecision: {
        opts: { $merge: action.payload.opts }
      }
    });
  case ACTIONS.START_EDITING_OBJECT:
    // todo: use reader/utils/moveModel
    return update(state, {
      pendingChanges: {
        [action.payload.type]: {
          [action.payload.vacolsId]: {
            $set: state.loadedQueue[action.payload.type][action.payload.vacolsId]
          }
        }
      }
    });
  case ACTIONS.CANCEL_EDITING_OBJECT:
    return update(state, {
      pendingChanges: {
        [action.payload.type]: {
          $unset: action.payload.vacolsId
        }
      }
    });
  case ACTIONS.UPDATE_APPEAL_ISSUE:
    const issues = state.pendingChanges.appeals[action.payload.appealId].attributes.issues;
    const issueIdx = _.findIndex(issues, (issue) => issue.id === action.payload.issueId);

    return update(state, {
      pendingChanges: {
        appeals: {
          [action.payload.appealId]: {
            attributes: {
              issues: {
                [issueIdx]: {
                  $merge: action.payload.attributes
                }
              }
            }
          }
        }
      }
    });
  case ACTIONS.UPDATE_OBJECT:
    return update(state, {
      pendingChanges: {
        [action.payload.type]: {
          [action.payload.vacolsId]: {
            attributes: {
              $merge: action.payload.attributes
            }
          }
        }
      }
    });
  // todo: request_edit_object, success, failure
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
