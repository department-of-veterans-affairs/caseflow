import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { ACTIONS } from './constants';
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';
import { combineReducers } from 'redux';
import _ from 'lodash';

export const initialState = {
  judges: {},
  loadedQueue: {
    appeals: {},
    tasks: {},
    loadedUserId: null
  },
  ui: {
    selectingJudge: false,
    breadcrumbs: [],
    highlightFormItems: false
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
    tasks: {},
    taskDecision: {
      type: '',
      opts: {}
    }
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
  case ACTIONS.RECEIVE_JUDGE_DETAILS:
    return update(state, {
      judges: {
        $set: action.payload.judges
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
      pendingChanges: {
        taskDecision: {
          type: { $set: action.payload.type }
        }
      }
    });
  case ACTIONS.SET_DECISION_OPTIONS:
    return update(state, {
      pendingChanges: {
        taskDecision: {
          opts: { $merge: action.payload.opts }
        }
      }
    });
  case ACTIONS.RESET_DECISION_OPTIONS:
    return update(state, {
      pendingChanges: {
        taskDecision: {
          $set: initialState.pendingChanges.taskDecision
        }
      }
    });
  case ACTIONS.START_EDITING_APPEAL:
    return update(state, {
      pendingChanges: {
        appeals: {
          [action.payload.vacolsId]: {
            $set: state.loadedQueue.appeals[action.payload.vacolsId]
          }
        }
      }
    });
  case ACTIONS.CANCEL_EDITING_APPEAL:
    return update(state, {
      pendingChanges: {
        appeals: {
          $unset: action.payload.vacolsId
        }
      }
    });
  case ACTIONS.UPDATE_APPEAL_ISSUE: {
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
  }
  case ACTIONS.HIGHLIGHT_INVALID_FORM_ITEMS:
    return update(state, {
      ui: {
        highlightFormItems: {
          $set: action.payload.highlight
        }
      }
    });
  case ACTIONS.SET_SELECTING_JUDGE:
    return update(state, {
      ui: {
        selectingJudge: { $set: action.payload.selectingJudge }
      }
    });
  case ACTIONS.PUSH_BREADCRUMB:
    return update(state, {
      ui: {
        breadcrumbs: {
          $push: action.payload.crumbs
        }
      }
    });
  case ACTIONS.RESET_BREADCRUMBS:
    return update(state, {
      ui: {
        breadcrumbs: {
          $set: []
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
