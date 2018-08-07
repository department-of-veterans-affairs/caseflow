/* eslint-disable max-lines */
// @flow

import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { combineReducers } from 'redux';
import _ from 'lodash';

import { ACTIONS } from './constants';

import caseListReducer from './CaseList/CaseListReducer';
import uiReducer from './uiReducer/uiReducer';
import type { QueueState } from './types/state';

// TODO: Remove this when we move entirely over to the appeals search.
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';

export const initialState = {
  judges: {},
  tasks: {},
  amaTasks: {},
  appeals: {},
  appealDetails: {},
  editingIssue: {},
  docCountForAppeal: {},
  newDocsForAppeal: {},

  /**
   * `stagedChanges` is an object of appeals that have been modified since
   * loading from the server. When a user starts editing an appeal/task, we copy
   * it from `loadedQueue[obj.type]`.
   */
  stagedChanges: {
    appeals: {},
    taskDecision: {
      type: '',
      opts: {}
    }
  },
  attorneysOfJudge: [],
  attorneyAppealsLoadingState: {},
  isTaskAssignedToUserSelected: {},
  attorneys: {}
};

// eslint-disable-next-line max-statements
const workQueueReducer = (state = initialState, action = {}): QueueState => {
  switch (action.type) {
  case ACTIONS.RECEIVE_QUEUE_DETAILS:
    return update(state, {
      appeals: {
        $merge: action.payload.appeals
      },
      tasks: {
        $merge: action.payload.tasks
      }
    });
  case ACTIONS.RECEIVE_APPEAL_DETAILS:
    return update(state, {
      appeals: {
        $merge: action.payload.appeals
      },
      appealDetails: {
        $merge: action.payload.appealDetails
      }
    });
  case ACTIONS.RECEIVE_TASKS:
    return update(state, {
      tasks: {
        $merge: action.payload.tasks
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
      appeals: { $unset: action.payload.appealId },
      tasks: { $unset: action.payload.appealId }
    });
  case ACTIONS.EDIT_APPEAL:
    return update(state, {
      appealDetails: {
        [action.payload.appealId]: {
          attributes: {
            $merge: action.payload.attributes
          }
        }
      }
    });
  case ACTIONS.RECEIVE_NEW_FILES:
    return update(state, {
      newDocsForAppeal: {
        [action.payload.appealId]: {
          $set: {
            docs: action.payload.newDocuments
          }
        }
      }
    });
  case ACTIONS.ERROR_ON_RECEIVE_NEW_FILES:
    return update(state, {
      newDocsForAppeal: {
        [action.payload.appealId]: {
          $set: {
            error: action.payload.error
          }
        }
      }
    });
  case ACTIONS.SET_APPEAL_DOC_COUNT:
    return update(state, {
      docCountForAppeal: {
        [action.payload.appealId]: {
          $set: action.payload.docCount
        }
      }
    });
  case ACTIONS.SET_REVIEW_ACTION_TYPE:
    return update(state, {
      stagedChanges: {
        taskDecision: {
          type: { $set: action.payload.type }
        }
      }
    });
  case ACTIONS.SET_DECISION_OPTIONS:
    return update(state, {
      stagedChanges: {
        taskDecision: {
          opts: { $merge: action.payload.opts }
        }
      }
    });
  case ACTIONS.RESET_DECISION_OPTIONS:
    return update(state, {
      stagedChanges: {
        taskDecision: {
          opts: { $set: initialState.stagedChanges.taskDecision.opts }
        }
      }
    });
  case ACTIONS.STAGE_APPEAL:
    return update(state, {
      stagedChanges: {
        appeals: {
          [action.payload.appealId]: {
            $set: state.appealDetails[action.payload.appealId]
          }
        }
      }
    });
  case ACTIONS.EDIT_STAGED_APPEAL:
    return update(state, {
      stagedChanges: {
        appeals: {
          [action.payload.appealId]: {
            attributes: {
              $merge: action.payload.attributes
            }
          }
        }
      }
    });
  case ACTIONS.CHECKOUT_STAGED_APPEAL:
    return update(state, {
      stagedChanges: {
        appeals: {
          $unset: action.payload.appealId
        }
      }
    });
  case ACTIONS.START_EDITING_APPEAL_ISSUE: {
    const { appealId, issueId } = action.payload;
    const issues = state.stagedChanges.appeals[appealId].attributes.issues;

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
      stagedChanges: { appeals }
    } = state;
    const issues = appeals[appealId].attributes.issues;
    let updatedIssues = [];

    const editingIssueId = Number(editingIssue.vacols_sequence_id);
    const editingExistingIssue = _.map(issues, 'vacols_sequence_id').includes(editingIssueId);

    if (editingExistingIssue) {
      updatedIssues = _.map(issues, (issue) => issue.vacols_sequence_id === editingIssueId ? editingIssue : issue);
    } else {
      updatedIssues = issues.concat(editingIssue);
    }

    return update(state, {
      stagedChanges: {
        appeals: {
          [appealId]: {
            attributes: {
              issues: {
                $set: updatedIssues
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
  case ACTIONS.DELETE_EDITING_APPEAL_ISSUE: {
    const { appealId, issueId } = action.payload;
    const { stagedChanges: { appeals } } = state;

    const issues = _.reject(appeals[appealId].attributes.issues,
      (issue) => issue.vacols_sequence_id === Number(issueId));

    return update(state, {
      stagedChanges: {
        appeals: {
          [appealId]: {
            attributes: {
              issues: {
                $set: issues
              }
            }
          }
        },
        editingIssue: {
          $set: {}
        }
      }
    });
  }
  case ACTIONS.SET_ATTORNEYS_OF_JUDGE:
    return update(state, {
      attorneysOfJudge: {
        $set: action.payload.attorneys
      }
    });
  case ACTIONS.REQUEST_TASKS_AND_APPEALS_OF_ATTORNEY:
    return update(state, {
      attorneyAppealsLoadingState: {
        [action.payload.attorneyId]: {
          $set: {
            state: 'LOADING'
          }
        }
      }
    });
  case ACTIONS.SET_TASKS_AND_APPEALS_OF_ATTORNEY:
    return update(state, {
      attorneyAppealsLoadingState: {
        [action.payload.attorneyId]: {
          $set: {
            state: 'LOADED'
          }
        }
      },
      appeals: {
        $merge: action.payload.appeals
      },
      tasks: {
        $merge: action.payload.tasks
      }
    });
  case ACTIONS.ERROR_TASKS_AND_APPEALS_OF_ATTORNEY:
    return update(state, {
      attorneyAppealsLoadingState: {
        [action.payload.attorneyId]: {
          $set: {
            state: 'FAILED',
            error: action.payload.error
          }
        }
      }
    });
  case ACTIONS.SET_SELECTION_OF_TASK_OF_USER: {
    const isTaskSelected = update(state.isTaskAssignedToUserSelected[action.payload.userId] || {}, {
      [action.payload.taskId]: {
        $set: action.payload.selected
      }
    });

    return update(state, {
      isTaskAssignedToUserSelected: {
        [action.payload.userId]: {
          $set: isTaskSelected
        }
      }
    });
  }
  case ACTIONS.RECEIVE_ALL_ATTORNEYS:
    return update(state, {
      attorneys: {
        $set: {
          data: action.payload.attorneys
        }
      }
    });
  case ACTIONS.ERROR_LOADING_ATTORNEYS:
    return update(state, {
      attorneys: {
        $set: {
          error: action.payload.error
        }
      }
    });
  case ACTIONS.AMA_TASKS_RECEIVED:
    return {
      ...state,
      amaTasks: {
        ...state.amaTasks,
        ...action.payload.amaTasks
      }
    };
  default:
    return state;
  }
};

const rootReducer = combineReducers({
  caseList: caseListReducer,
  caseSelect: caseSelectReducer,
  queue: workQueueReducer,
  ui: uiReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
