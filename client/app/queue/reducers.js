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

const receiveQueueDetails = (state, action) => {
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
};

const receiveAppealDetails = (state, action) => {
  return update(state, {
    appeals: {
      $merge: action.payload.appeals
    },
    appealDetails: {
      $merge: action.payload.appealDetails
    }
  });
};

const receiveClaimReviewDetails = (state, action) => {
  return update(state, {
    claimReviews: {
      $merge: action.payload.claimReviews
    }
  });
};

const receiveTasks = (state, action) => {
  return update(state, {
    tasks: {
      $merge: action.payload.tasks ? action.payload.tasks : {}
    },
    amaTasks: {
      $merge: action.payload.amaTasks ? action.payload.amaTasks : {}
    }
  });
};

const receiveAmaTasks = (state, action) => {
  return update(state, {
    amaTasks: {
      $set: action.payload.amaTasks
    }
  });
};

const receiveJudgeDetails = (state, action) => {
  return update(state, {
    judges: {
      $set: action.payload.judges
    }
  });
};

const deleteAppeal = (state, action) => {
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
};

const deleteTask = (state, action) => {
  return update(state, {
    tasks: { $unset: action.payload.taskId }
  });
};

const editAppeal = (state, action) => {
  return update(state, {
    appealDetails: {
      [action.payload.appealId]: {
        $merge: action.payload.attributes
      }
    }
  });
};

const receiveNewFilesForAppeal = (state, action) => {
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
};

const errorOnReceiveNewFilesForAppeal = (state, action) => {
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
};

const startedLoadingDocumentsForAppeal = (state, action) => {
  return {
    ...state,
    newDocsForAppeal: {
      ...state.newDocsForAppeal,
      [action.payload.appealId]: {
        loading: true
      }
    }
  };
};

const receiveNewFilesForTask = (state, action) => {
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
};

const errorOnReceiveNewFilesForTask = (state, action) => {
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
};

const startedLoadingDocumentsForTask = (state, action) => {
  return {
    ...state,
    newDocsForTask: {
      ...state.newDocsForTask,
      [action.payload.taskId]: {
        loading: true
      }
    }
  };
};

const startedDocCountRequest = (state, action) => {
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
};

const errorOnReceiveDocumentCount = (state, action) => {
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
};

const setAppealDocCount = (state, action) => {
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
};

const setMostRecentlyHeldHearingForAppeal = (state, action) => {
  return update(state, {
    mostRecentlyHeldHearingForAppeal: {
      [action.payload.appealId]: {
        $set: action.payload.hearing
      }
    }
  });
};

const setDecisionOptions = (state, action) => {
  return update(state, {
    stagedChanges: {
      taskDecision: {
        opts: { $merge: action.payload.opts }
      }
    }
  });
};

const resetDecisionOptions = (state, action) => {
  return update(state, {
    stagedChanges: {
      taskDecision: {
        opts: { $set: initialState.stagedChanges.taskDecision.opts }
      }
    }
  });
};

const stageAppeal = (state, action) => {
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
};

const editStagedAppeal = (state, action) => {
  return update(state, {
    stagedChanges: {
      appeals: {
        [action.payload.appealId]: {
          $merge: action.payload.attributes
        }
      }
    }
  });
};

const checkoutStagedAppeal = (state, action) => {
  return update(state, {
    stagedChanges: {
      appeals: {
        $unset: action.payload.appealId
      }
    }
  });
};

const startEditingAppealIssue = (state, action) => {
  const { appealId, issueId } = action.payload;
  const issues = state.stagedChanges.appeals[appealId].issues;

  return update(state, {
    editingIssue: {
      $set: _.find(issues, (issue) => issue.id === Number(issueId))
    }
  });
};

const cancelEditingAppealIssue = (state, action) => {
  return update(state, {
    editingIssue: {
      $set: {}
    }
  });
};

const updateEditingAppealIssue = (state, action) => {
  return update(state, {
    editingIssue: {
      $merge: action.payload.attributes
    }
  });
};

const saveEditedAppealIssue = (state, action) => {
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
};

const deleteEditingAppealIssue = (state, action) => {
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
};

const setAttorneysOfJudge = (state, action) => {
  return update(state, {
    attorneysOfJudge: {
      $set: action.payload.attorneys
    }
  });
};

const requestTasksAndAppealsOfAttorney = (state, action) => {
  return update(state, {
    attorneyAppealsLoadingState: {
      [action.payload.attorneyId]: {
        $set: {
          state: 'LOADING'
        }
      }
    }
  });
};

const setTasksAndAppealsOfAttorney = (state, action) => {
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
};

const errorTasksAndAppealsOfAttorney = (state, action) => {
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
};

const setSelectionOfTaskOfUser = (state, action) => {
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
};

const bulkAssignTasks = (state, action) => {
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
};

const setPendingDistribution = (state, action) => {
  return update(state, {
    pendingDistribution: {
      $set: action.payload.distribution
    }
  });
};

const receiveAllAttorneys = (state, action) => {
  return update(state, {
    attorneys: {
      $set: {
        data: action.payload.attorneys
      }
    }
  });
};

const errorLoadingAttorneys = (state, action) => {
  return update(state, {
    attorneys: {
      $set: {
        error: action.payload.error
      }
    }
  });
};

const setTaskAttrs = (state, action) => {
  const { uniqueId } = action.payload;
  const taskType = uniqueId in state.amaTasks ? 'amaTasks' : 'tasks';

  return update(state, {
    [taskType]: {
      [uniqueId]: {
        $merge: action.payload.attributes
      }
    }
  });
};

const setAppealAttrs = (state, action) => {
  return update(state, {
    appealDetails: {
      [action.payload.appealId]: {
        $merge: action.payload.attributes
      }
    }
  });
};

const setSpecialIssue = (state, action) => {
  return update(state, {
    specialIssues: {
      $merge: action.payload.specialIssues
    }
  });
};

const setAppealAod = (state, action) => {
  return update(state, {
    appeals: {
      [action.payload.externalAppealId]: {
        isAdvancedOnDocket: {
          $set: true
        }
      }
    }
  });
};

const startedLoadingAppealValue = (state, action) => {
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
};

const receiveAppealValue = (state, action) => {
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
};

const errorOnReceiveAppealValue = (state, action) => {
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
};

const setQueueConfig = (state, action) => update(state, { queueConfig: { $set: action.payload.config } });

// eslint-disable-next-line max-statements
export const workQueueReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.RECEIVE_QUEUE_DETAILS:
    return receiveQueueDetails(state, action);
  case ACTIONS.RECEIVE_APPEAL_DETAILS:
    return receiveAppealDetails(state, action);
  case ACTIONS.RECEIVE_CLAIM_REVIEW_DETAILS:
    return receiveClaimReviewDetails(state, action);
  case ACTIONS.RECEIVE_TASKS:
    return receiveTasks(state, action);
  case ACTIONS.RECEIVE_AMA_TASKS:
    return receiveAmaTasks(state, action);
  case ACTIONS.RECEIVE_JUDGE_DETAILS:
    return receiveJudgeDetails(state, action);
  case ACTIONS.DELETE_APPEAL:
    return deleteAppeal(state, action);
  case ACTIONS.DELETE_TASK:
    return deleteTask(state, action);
  case ACTIONS.EDIT_APPEAL:
    return editAppeal(state, action);
  case ACTIONS.RECEIVE_NEW_FILES_FOR_APPEAL:
    return receiveNewFilesForAppeal(state, action);
  case ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_APPEAL:
    return errorOnReceiveNewFilesForAppeal(state, action);
  case ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_APPEAL:
    return startedLoadingDocumentsForAppeal(state, action);
  case ACTIONS.RECEIVE_NEW_FILES_FOR_TASK:
    return receiveNewFilesForTask(state, action);
  case ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_TASK:
    return errorOnReceiveNewFilesForTask(state, action);
  case ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_TASK:
    return startedLoadingDocumentsForTask(state, action);
  case ACTIONS.STARTED_DOC_COUNT_REQUEST:
    return startedDocCountRequest(state, action);
  case ACTIONS.ERROR_ON_RECEIVE_DOCUMENT_COUNT:
    return errorOnReceiveDocumentCount(state, action);
  case ACTIONS.SET_APPEAL_DOC_COUNT:
    return setAppealDocCount(state, action);
  case ACTIONS.SET_MOST_RECENTLY_HELD_HEARING_FOR_APPEAL:
    return setMostRecentlyHeldHearingForAppeal(state, action);
  case ACTIONS.SET_DECISION_OPTIONS:
    return setDecisionOptions(state, action);
  case ACTIONS.RESET_DECISION_OPTIONS:
    return resetDecisionOptions(state, action);
  case ACTIONS.STAGE_APPEAL:
    return stageAppeal(state, action);
  case ACTIONS.EDIT_STAGED_APPEAL:
    return editStagedAppeal(state, action);
  case ACTIONS.CHECKOUT_STAGED_APPEAL:
    return checkoutStagedAppeal(state, action);
  case ACTIONS.START_EDITING_APPEAL_ISSUE:
    return startEditingAppealIssue(state, action);
  case ACTIONS.CANCEL_EDITING_APPEAL_ISSUE:
    return cancelEditingAppealIssue(state, action);
  case ACTIONS.UPDATE_EDITING_APPEAL_ISSUE:
    return updateEditingAppealIssue(state, action);
  case ACTIONS.SAVE_EDITED_APPEAL_ISSUE:
    return saveEditedAppealIssue(state, action);
  case ACTIONS.DELETE_EDITING_APPEAL_ISSUE:
    return deleteEditingAppealIssue(state, action);
  case ACTIONS.SET_ATTORNEYS_OF_JUDGE:
    return setAttorneysOfJudge(state, action);
  case ACTIONS.REQUEST_TASKS_AND_APPEALS_OF_ATTORNEY:
    return requestTasksAndAppealsOfAttorney(state, action);
  case ACTIONS.SET_TASKS_AND_APPEALS_OF_ATTORNEY:
    return setTasksAndAppealsOfAttorney(state, action);
  case ACTIONS.ERROR_TASKS_AND_APPEALS_OF_ATTORNEY:
    return errorTasksAndAppealsOfAttorney(state, action);
  case ACTIONS.SET_SELECTION_OF_TASK_OF_USER:
    return setSelectionOfTaskOfUser(state, action);
  case ACTIONS.BULK_ASSIGN_TASKS:
    return bulkAssignTasks(state, action);
  case ACTIONS.SET_PENDING_DISTRIBUTION:
    return setPendingDistribution(state, action);
  case ACTIONS.RECEIVE_ALL_ATTORNEYS:
    return receiveAllAttorneys(state, action);
  case ACTIONS.ERROR_LOADING_ATTORNEYS:
    return errorLoadingAttorneys(state, action);
  case ACTIONS.SET_TASK_ATTRS:
    return setTaskAttrs(state, action);
  case ACTIONS.SET_APPEAL_ATTRS:
    return setAppealAttrs(state, action);
  case ACTIONS.SET_SPECIAL_ISSUE:
    return setSpecialIssue(state, action);
  case ACTIONS.SET_APPEAL_AOD:
    return setAppealAod(state, action);
  case ACTIONS.STARTED_LOADING_APPEAL_VALUE:
    return startedLoadingAppealValue(state, action);
  case ACTIONS.RECEIVE_APPEAL_VALUE:
    return receiveAppealValue(state, action);
  case ACTIONS.ERROR_ON_RECEIVE_APPEAL_VALUE:
    return errorOnReceiveAppealValue(state, action);
  case ACTIONS.SET_QUEUE_CONFIG:
    return setQueueConfig(state, action);
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
