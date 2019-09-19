/* eslint-disable max-lines */

import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { combineReducers } from 'redux';
import _ from 'lodash';

import { ACTIONS } from './constants';

import caseListReducer from './CaseList/CaseListReducer';
import uiReducer from './uiReducer/uiReducer';
import teamManagementReducer from './teamManagement/reducers';

import commonComponentsReducer from '../components/common/reducers';
import mtvReducer from './mtv/reducers';

// TODO: Remove this when we move entirely over to the appeals search.
import caseSelectReducer from '../reader/CaseSelect/CaseSelectReducer';

export const initialState = {
  judges: {},
  tasks: {},
  amaTasks: {},
  appeals: {},
  appealDetails: {},
  claimReviews: {},
  editingIssue: {},
  docCountForAppeal: {},
  mostRecentlyHeldHearingForAppeal: {},
  newDocsForAppeal: {},
  newDocsForTask: {},
  specialIssues: {},

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
  tasksAssignedByBulk: {},
  pendingDistribution: null,
  attorneys: {},
  organizationId: null,
  organizations: [],
  loadingAppealDetail: {},
  queueConfig: {}
};

// eslint-disable-next-line max-statements
export const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_QUEUE_DETAILS:
    return update(state, {
      appeals: {
        $merge: action.payload.appeals
      },
      tasks: {
        $merge: action.payload.tasks ? action.payload.tasks : {}
      },
      amaTasks: {
        $merge: action.payload.amaTasks ? action.payload.amaTasks : {}
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
  case ACTIONS.RECEIVE_CLAIM_REVIEW_DETAILS:
    return update(state, {
      claimReviews: {
        $merge: action.payload.claimReviews
      }
    });
  case ACTIONS.RECEIVE_TASKS:
    return update(state, {
      tasks: {
        $merge: action.payload.tasks ? action.payload.tasks : {}
      },
      amaTasks: {
        $merge: action.payload.amaTasks ? action.payload.amaTasks : {}
      }
    });
  case ACTIONS.RECEIVE_AMA_TASKS:
    return update(state, {
      amaTasks: {
        $set: action.payload.amaTasks
      }
    });
  case ACTIONS.RECEIVE_JUDGE_DETAILS:
    return update(state, {
      judges: {
        $set: action.payload.judges
      }
    });
  case ACTIONS.DELETE_APPEAL: {
    const amaTasksIds = _.map(
      _.filter(state.amaTasks, (task) => task.externalAppealId === action.payload.appealId),
      (task) => task.uniqueId
    );

    return update(state, {
      tasks: { $unset: action.payload.appealId },
      amaTasks: { $unset: amaTasksIds },
      appeals: { $unset: action.payload.appealId },
      appealDetails: { $unset: action.payload.appealId }
    });
  }
  case ACTIONS.DELETE_TASK: {
    return update(state, {
      tasks: { $unset: action.payload.taskId }
    });
  }
  case ACTIONS.EDIT_APPEAL:
    return update(state, {
      appealDetails: {
        [action.payload.appealId]: {
          $merge: action.payload.attributes
        }
      }
    });
  case ACTIONS.RECEIVE_NEW_FILES_FOR_APPEAL:
    return update(state, {
      newDocsForAppeal: {
        [action.payload.appealId]: {
          $set: {
            docs: action.payload.newDocuments,
            loading: false
          }
        }
      }
    });
  case ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_APPEAL:
    return update(state, {
      newDocsForAppeal: {
        [action.payload.appealId]: {
          $set: {
            error: action.payload.error,
            loading: false
          }
        }
      }
    });
  case ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_APPEAL:
    return {
      ...state,
      newDocsForAppeal: {
        ...state.newDocsForAppeal,
        [action.payload.appealId]: {
          loading: true
        }
      }
    };
  case ACTIONS.RECEIVE_NEW_FILES_FOR_TASK:
    return update(state, {
      newDocsForTask: {
        [action.payload.taskId]: {
          $set: {
            docs: action.payload.newDocuments,
            loading: false
          }
        }
      }
    });
  case ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_TASK:
    return update(state, {
      newDocsForTask: {
        [action.payload.taskId]: {
          $set: {
            error: action.payload.error,
            loading: false
          }
        }
      }
    });
  case ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_TASK:
    return {
      ...state,
      newDocsForTask: {
        ...state.newDocsForTask,
        [action.payload.taskId]: {
          loading: true
        }
      }
    };
  case ACTIONS.STARTED_DOC_COUNT_REQUEST:
    return {
      ...state,
      docCountForAppeal: {
        ...state.docCountForAppeal,
        [action.payload.appealId]: {
          ...state.docCountForAppeal[action.payload.appealId],
          error: null,
          loading: true
        }
      }
    };
  case ACTIONS.ERROR_ON_RECEIVE_DOCUMENT_COUNT:
    return {
      ...state,
      docCountForAppeal: {
        ...state.docCountForAppeal,
        [action.payload.appealId]: {
          ...state.docCountForAppeal[action.payload.appealId],
          error: 'Failed to Load',
          loading: false
        }
      }
    };
  case ACTIONS.SET_APPEAL_DOC_COUNT:
    return update(state, {
      docCountForAppeal: {
        [action.payload.appealId]: {
          $set: {
            docCountText: action.payload.docCountText,
            loading: false
          }
        }
      }
    });
  case ACTIONS.SET_MOST_RECENTLY_HELD_HEARING_FOR_APPEAL:
    return update(state, {
      mostRecentlyHeldHearingForAppeal: {
        [action.payload.appealId]: {
          $set: action.payload.hearing
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
            $set: { ...state.appeals[action.payload.appealId],
              ...state.appealDetails[action.payload.appealId] }
          }
        }
      }
    });
  case ACTIONS.EDIT_STAGED_APPEAL:
    return update(state, {
      stagedChanges: {
        appeals: {
          [action.payload.appealId]: {
            $merge: action.payload.attributes
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
    const issues = state.stagedChanges.appeals[appealId].issues;

    return update(state, {
      editingIssue: {
        $set: _.find(issues, (issue) => issue.id === Number(issueId))
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
    const issues = appeals[appealId].issues;
    let updatedIssues = [];

    const editingIssueId = Number(editingIssue.id);
    const editingExistingIssue = _.map(issues, 'id').includes(editingIssueId);

    if (editingExistingIssue) {
      updatedIssues = _.map(issues, (issue) => (issue.id === editingIssueId ? editingIssue : issue));
    } else {
      updatedIssues = issues.concat(editingIssue);
    }

    return update(state, {
      stagedChanges: {
        appeals: {
          [appealId]: {
            issues: {
              $set: updatedIssues
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
    const {
      stagedChanges: { appeals }
    } = state;

    const issues = _.reject(appeals[appealId].issues, (issue) => issue.id === Number(issueId));

    return update(state, {
      stagedChanges: {
        appeals: {
          [appealId]: {
            issues: {
              $set: issues
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
  case ACTIONS.BULK_ASSIGN_TASKS:
    return update(state, {
      tasksAssignedByBulk: {
        $set: {
          assignedUser: action.payload.assignedUser,
          regionalOffice: action.payload.regionalOffice,
          taskType: action.payload.taskType,
          numberOfTasks: action.payload.numberOfTasks
        }
      }
    });
  case ACTIONS.SET_PENDING_DISTRIBUTION:
    return update(state, {
      pendingDistribution: {
        $set: action.payload.distribution
      }
    });
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
  case ACTIONS.SET_TASK_ATTRS: {
    const { uniqueId } = action.payload;
    const taskType = uniqueId in state.amaTasks ? 'amaTasks' : 'tasks';

    return update(state, {
      [taskType]: {
        [uniqueId]: {
          $merge: action.payload.attributes
        }
      }
    });
  }
  case ACTIONS.SET_APPEAL_ATTRS: {
    return update(state, {
      appealDetails: {
        [action.payload.appealId]: {
          $merge: action.payload.attributes
        }
      }
    });
  }
  case ACTIONS.SET_SPECIAL_ISSUE: {
    return update(state, {
      specialIssues: {
        $merge: action.payload.specialIssues
      }
    });
  }
  case ACTIONS.SET_APPEAL_AOD:
    return update(state, {
      appeals: {
        [action.payload.externalAppealId]: {
          isAdvancedOnDocket: {
            $set: true
          }
        }
      }
    });
  case ACTIONS.STARTED_LOADING_APPEAL_VALUE:
    return update(state, {
      loadingAppealDetail: {
        $merge: {
          [action.payload.appealId]: {
            [action.payload.name]: {
              loading: true
            }
          }
        }
      }
    });
  case ACTIONS.RECEIVE_APPEAL_VALUE: {
    const existingState = state.loadingAppealDetail[action.payload.appealId] || {};

    return update(state, {
      loadingAppealDetail: {
        $merge: {
          [action.payload.appealId]: {
            ...existingState,
            [action.payload.name]: {
              loading: false
            }
          }
        }
      },
      appealDetails: {
        [action.payload.appealId]: {
          $merge: {
            [action.payload.name]: action.payload.response
          }
        }
      }
    });
  }
  case ACTIONS.ERROR_ON_RECEIVE_APPEAL_VALUE: {
    const existingState = state.loadingAppealDetail[action.payload.appealId] || {};

    return update(state, {
      loadingAppealDetail: {
        $merge: {
          [action.payload.appealId]: {
            ...existingState,
            [action.payload.name]: {
              loading: false,
              error: action.payload.error
            }
          }
        }
      }
    });
  }
  case ACTIONS.SET_QUEUE_CONFIG: {
    return update(state, { queueConfig: { $set: action.payload.config } });
  }
  default:
    return state;
  }
};

const rootReducer = combineReducers({
  caseList: caseListReducer,
  caseSelect: caseSelectReducer,
  queue: workQueueReducer,
  teamManagement: teamManagementReducer,
  ui: uiReducer,
  components: commonComponentsReducer,
  mtv: mtvReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
