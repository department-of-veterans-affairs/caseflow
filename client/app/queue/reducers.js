import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { combineReducers } from 'redux';
import _ from 'lodash';

import { ACTIONS } from './constants';

import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';
import uiReducer from './uiReducer/uiReducer';

export const initialState = {
  judges: {},
  loadedQueue: {
    appeals: {},
    tasks: {},
    loadedUserId: null
  },
  editingIssue: {},

  /**
   * `pendingChanges` is an object of appeals that have been modified since
   * loading from the server. When a user starts editing an appeal/task, we copy
   * it from `loadedQueue[obj.type]`.
   */
  pendingChanges: {
    appeals: {},
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
  case ACTIONS.DELETE_APPEAL:
    return update(state, {
      loadedQueue: {
        appeals: { $unset: action.payload.appealId },
        tasks: { $unset: action.payload.appealId }
      }
    });
  case ACTIONS.SET_APPEAL_DOC_COUNT:
  case ACTIONS.LOAD_APPEAL_DOC_COUNT_FAILURE:
    return update(state, {
      loadedQueue: {
        appeals: {
          [action.payload.appealId]: {
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
          [action.payload.appealId]: {
            $set: state.loadedQueue.appeals[action.payload.appealId]
          }
        }
      }
    });
  case ACTIONS.EDIT_APPEAL:
    return update(state, {
      pendingChanges: {
        appeals: {
          [action.payload.appealId]: {
            $merge: action.payload.attributes
          }
        }
      }
    });
  case ACTIONS.CANCEL_EDITING_APPEAL:
    return update(state, {
      pendingChanges: {
        appeals: {
          $unset: action.payload.appealId
        }
      }
    });
  case ACTIONS.START_EDITING_APPEAL_ISSUE: {
    const { appealId, issueId } = action.payload;
    const issues = state.pendingChanges.appeals[appealId].attributes.issues;

    return update(state, {
      editingIssue: {
        $set: _.find(issues, (issue) => issue.vacols_sequence_id === Number(issueId))
      }
    });
  }
  case ACTIONS.CANCEL_EDITING_APPEAL_ISSUE:
    return update(state, {
      editingIssue: {
        $set: {}
      }
    });
  case ACTIONS.UPDATE_EDITING_APPEAL_ISSUE:
    return update(state, {
      editingIssue: {
        $merge: action.payload.attributes
      }
    });
  case ACTIONS.SAVE_EDITED_APPEAL_ISSUE: {
    const { appealId } = action.payload;
    const {
      editingIssue,
      pendingChanges: { appeals }
    } = state;

    const issues = appeals[appealId].attributes.issues.map((issue) =>
      issue.vacols_sequence_id === Number(editingIssue.vacols_sequence_id) ?
        editingIssue : issue);

    // todo: if (idx === -1) { push } (#4477)
    return update(state, {
      pendingChanges: {
        appeals: {
          [appealId]: {
            attributes: {
              issues: {
                $set: issues
              }
            }
          }
        }
      },
      editingIssue: {
        $set: {}
      }
    });
  }
  default:
    return state;
  }
};

const rootReducer = combineReducers({
  ui: uiReducer,
  queue: workQueueReducer,
  caseSelect: caseSelectReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
