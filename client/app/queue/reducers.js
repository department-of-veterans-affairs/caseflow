// @flow
import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { combineReducers } from 'redux';
import _ from 'lodash';

import { ACTIONS } from './constants';

import * as caseDetailReducer from './CaseDetail/CaseDetailReducer';
import caseListReducer from './CaseList/CaseListReducer';
import * as uiReducer from './uiReducer/uiReducer';

// TODO: Remove this when we move entirely over to the appeals search.
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';

export type DeprecatedTask = {
  id: string
};

export type LoadedQueueTasks = { [string]: DeprecatedTask };

export type Task = {
  id: string,
  vacolsId: string,
  attributes: {
    added_by_css_id: string,
    added_by_name: string,
    appeal_id: string,
    assigned_by_first_name: string,
    assigned_by_last_name: string,
    assigned_on: string,
    docket_date: string,
    docket_name: string,
    document_id: string,
    due_on: string,
    task_id: string,
    task_type: string,
    user_id: string
  }
};

export type Tasks = { [string]: Task };

export type LoadedQueueAppeals = { [string]: Object };

export type TasksAndAppealsOfAttorney = {
  [string]: {
    state: string,
    data: {tasks: LoadedQueueTasks, appeals: LoadedQueueAppeals},
    error: {status: number, response: Object}
  }
};

export type AttorneysOfJudge = Array<Object>;

export type QueueState = {
  judges: Object,
  tasks: Tasks,
  loadedQueue: {
    appeals: LoadedQueueAppeals,
    tasks: LoadedQueueTasks,
    loadedUserId: string
  },
  editingIssue: Object,
  docCountForAppeal: {[string]: Object},
  stagedChanges: {
    appeals: {[string]: Object},
    taskDecision: {
      type: '',
      opts: {}
    }
  },
  attorneysOfJudge: AttorneysOfJudge,
  tasksAndAppealsOfAttorney: TasksAndAppealsOfAttorney,
  isVacolsIdAssignedToUserSelected: {[string]: {[string]: {[string]: boolean}}}
};

export const initialState = {
  judges: {},
  tasks: {},
  loadedQueue: {
    appeals: {},
    tasks: {},
    loadedUserId: null
  },
  editingIssue: {},
  docCountForAppeal: {},

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
  tasksAndAppealsOfAttorney: {},
  isVacolsIdAssignedToUserSelected: {}
};

// eslint-disable-next-line max-statements
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
      },
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
      loadedQueue: {
        appeals: { $unset: action.payload.appealId },
        tasks: { $unset: action.payload.appealId }
      }
    });
  case ACTIONS.EDIT_APPEAL:
    return update(state, {
      loadedQueue: {
        appeals: {
          [action.payload.appealId]: {
            attributes: {
              $merge: action.payload.attributes
            }
          }
        }
      }
    });
  case ACTIONS.SET_APPEAL_DOC_COUNT:
    return update(state, {
      docCountForAppeal: {
        [action.payload.vacolsId]: {
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
            $set: state.loadedQueue.appeals[action.payload.appealId]
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
      tasksAndAppealsOfAttorney: {
        [action.payload.attorneyId]: {
          $set: {
            state: 'LOADING'
          }
        }
      }
    });
  case ACTIONS.SET_TASKS_AND_APPEALS_OF_ATTORNEY:
    return update(state, {
      tasksAndAppealsOfAttorney: {
        [action.payload.attorneyId]: {
          $set: {
            state: 'LOADED',
            data: _.pick(action.payload, 'tasks', 'appeals')
          }
        }
      },
      tasks: {
        $merge: action.payload.tasks
      }
    });
  case ACTIONS.ERROR_TASKS_AND_APPEALS_OF_ATTORNEY:
    return update(state, {
      tasksAndAppealsOfAttorney: {
        [action.payload.attorneyId]: {
          $set: {
            state: 'FAILED',
            error: action.payload.error
          }
        }
      }
    });
  case ACTIONS.SET_SELECTION_OF_TASK_OF_USER: {
    const isVacolsIdSelected = update(state.isVacolsIdAssignedToUserSelected[action.payload.userId] || {}, {
      [action.payload.vacolsId]: {
        $set: action.payload.selected
      }
    });

    return update(state, {
      isVacolsIdAssignedToUserSelected: {
        [action.payload.userId]: {
          $set: isVacolsIdSelected
        }
      }
    });
  }
  default:
    return state;
  }
};

export type State = {
  caseDetail: caseDetailReducer.CaseDetailState,
  caseList: Object,
  caseSelect: Object,
  queue: QueueState,
  ui: uiReducer.UiState
};

const rootReducer = combineReducers({
  caseDetail: caseDetailReducer,
  caseList: caseListReducer,
  caseSelect: caseSelectReducer,
  queue: workQueueReducer,
  ui: uiReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
