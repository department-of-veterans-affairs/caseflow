/* eslint-disable max-lines */

import { timeFunction } from '../util/PerfDebug';
import { update } from '../util/ReducerUtil';
import { combineReducers } from 'redux';
import _ from 'lodash';

import { ACTIONS } from './constants';
import ApiUtil from '../util/ApiUtil';

import caseListReducer from './CaseList/CaseListReducer';
import uiReducer from './uiReducer/uiReducer';
import teamManagementReducer from './teamManagement/reducers';

import commonComponentsReducer from '../components/common/reducers';
import mtvReducer from './mtv/reducers';
import docketSwitchReducer from './docketSwitch/docketSwitchSlice';
import substituteAppellantReducer from './substituteAppellant/substituteAppellant.slice';

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

const clearAppealDetails = (state, action) => {
  return update(state, {
    appealDetails: { $unset: action.payload.appealId }
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

const editNodDateUpdates = (state, action) => {
  const nodDateUpdate = ApiUtil.convertToCamelCase(action.payload.nodDateUpdate);

  nodDateUpdate.appealId = action.payload.appealId;
  nodDateUpdate.userFirstName = action.payload.nodDateUpdate.updated_by.split(' ')[0];
  nodDateUpdate.userLastName = action.payload.nodDateUpdate.updated_by.split(' ')[
    action.payload.nodDateUpdate.updated_by.split(' ').length - 1
  ];

  return update(state, {
    appealDetails: {
      [action.payload.appealId]: {
        nodDateUpdates: {
          $push: [nodDateUpdate]
        }
      }
    }
  });
};

const setOvertime = (state, action) => {
  return update(state, {
    appeals: {
      [action.payload.appealId]: {
        $merge: { overtime: action.payload.overtime }
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
      $set: action.payload.attorneys.data.map((attorney) => attorney.attributes)
    }
  });
};

const incrementTaskCountForAttorney = (state, action) => {
  const {
    attorneysOfJudge
  } = state;

  attorneysOfJudge.forEach((attorney) => {
    if (action.payload.attorney.id === attorney.id) {
      attorney.active_task_count += 1;
    }
  });

  return update(state, {
    attorneysOfJudge: {
      $set: attorneysOfJudge
    }
  });
};

const decrementTaskCountForAttorney = (state, action) => {
  const {
    attorneysOfJudge
  } = state;

  attorneysOfJudge.forEach((attorney) => {
    if (action.payload.attorney.id === attorney.id.toString()) {
      attorney.active_task_count -= 1;
    }
  });

  return update(state, {
    attorneysOfJudge: {
      $set: attorneysOfJudge
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
  if (state.attorneyAppealsLoadingState[action.payload.attorneyId]?.state === 'FAILED') {
    return state;
  }

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

const clearSpecialIssue = (state) => {
  const { specialIssues } = state;

  Object.keys(specialIssues).forEach((specialIssue) => {
    if (specialIssues[specialIssue] === true) {
      specialIssues[specialIssue] = false;
    }
  });

  return update(state, {
    specialIssues: {
      $merge: specialIssues
    }
  });
};

const setAppealAod = (state, action) => {
  return update(state, {
    appeals: {
      [action.payload.externalAppealId]: {
        isAdvancedOnDocket: {
          $set: action.payload.granted
        }
      }
    }
  });
};

const startedLoadingAppealValue = (state, action) => {
  const existingState = state.loadingAppealDetail[action.payload.appealId] || {};

  return update(state, {
    loadingAppealDetail: {
      $merge: {
        [action.payload.appealId]: {
          ...existingState,
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
  const existingDetails = state.appealDetails[action.payload.appealId] || {};

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
      $merge: {
        [action.payload.appealId]: {
          ...existingDetails,
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

const createReducer = (handlers) => {
  return (state = initialState, action) => {
    return Object.prototype.hasOwnProperty.call(handlers, action.type) ? handlers[action.type](state, action) : state;
  };
};

export const workQueueReducer = createReducer({
  [ACTIONS.RECEIVE_QUEUE_DETAILS]: receiveQueueDetails,
  [ACTIONS.RECEIVE_APPEAL_DETAILS]: receiveAppealDetails,
  [ACTIONS.RECEIVE_CLAIM_REVIEW_DETAILS]: receiveClaimReviewDetails,
  [ACTIONS.RECEIVE_TASKS]: receiveTasks,
  [ACTIONS.RECEIVE_AMA_TASKS]: receiveAmaTasks,
  [ACTIONS.RECEIVE_JUDGE_DETAILS]: receiveJudgeDetails,
  [ACTIONS.DELETE_APPEAL]: deleteAppeal,
  [ACTIONS.CLEAR_APPEAL]: clearAppealDetails,
  [ACTIONS.DELETE_TASK]: deleteTask,
  [ACTIONS.EDIT_APPEAL]: editAppeal,
  [ACTIONS.EDIT_NOD_DATE_UPDATES]: editNodDateUpdates,
  [ACTIONS.SET_OVERTIME]: setOvertime,
  [ACTIONS.RECEIVE_NEW_FILES_FOR_APPEAL]: receiveNewFilesForAppeal,
  [ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_APPEAL]: errorOnReceiveNewFilesForAppeal,
  [ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_APPEAL]: startedLoadingDocumentsForAppeal,
  [ACTIONS.RECEIVE_NEW_FILES_FOR_TASK]: receiveNewFilesForTask,
  [ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_TASK]: errorOnReceiveNewFilesForTask,
  [ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_TASK]: startedLoadingDocumentsForTask,
  [ACTIONS.STARTED_DOC_COUNT_REQUEST]: startedDocCountRequest,
  [ACTIONS.ERROR_ON_RECEIVE_DOCUMENT_COUNT]: errorOnReceiveDocumentCount,
  [ACTIONS.SET_APPEAL_DOC_COUNT]: setAppealDocCount,
  [ACTIONS.SET_MOST_RECENTLY_HELD_HEARING_FOR_APPEAL]: setMostRecentlyHeldHearingForAppeal,
  [ACTIONS.SET_DECISION_OPTIONS]: setDecisionOptions,
  [ACTIONS.RESET_DECISION_OPTIONS]: resetDecisionOptions,
  [ACTIONS.STAGE_APPEAL]: stageAppeal,
  [ACTIONS.EDIT_STAGED_APPEAL]: editStagedAppeal,
  [ACTIONS.CHECKOUT_STAGED_APPEAL]: checkoutStagedAppeal,
  [ACTIONS.START_EDITING_APPEAL_ISSUE]: startEditingAppealIssue,
  [ACTIONS.CANCEL_EDITING_APPEAL_ISSUE]: cancelEditingAppealIssue,
  [ACTIONS.UPDATE_EDITING_APPEAL_ISSUE]: updateEditingAppealIssue,
  [ACTIONS.SAVE_EDITED_APPEAL_ISSUE]: saveEditedAppealIssue,
  [ACTIONS.DELETE_EDITING_APPEAL_ISSUE]: deleteEditingAppealIssue,
  [ACTIONS.SET_ATTORNEYS_OF_JUDGE]: setAttorneysOfJudge,
  [ACTIONS.INCREMENT_TASK_COUNT_FOR_ATTORNEY]: incrementTaskCountForAttorney,
  [ACTIONS.DECREMENT_TASK_COUNT_FOR_ATTORNEY]: decrementTaskCountForAttorney,
  [ACTIONS.REQUEST_TASKS_AND_APPEALS_OF_ATTORNEY]: requestTasksAndAppealsOfAttorney,
  [ACTIONS.SET_TASKS_AND_APPEALS_OF_ATTORNEY]: setTasksAndAppealsOfAttorney,
  [ACTIONS.ERROR_TASKS_AND_APPEALS_OF_ATTORNEY]: errorTasksAndAppealsOfAttorney,
  [ACTIONS.SET_SELECTION_OF_TASK_OF_USER]: setSelectionOfTaskOfUser,
  [ACTIONS.SET_PENDING_DISTRIBUTION]: setPendingDistribution,
  [ACTIONS.RECEIVE_ALL_ATTORNEYS]: receiveAllAttorneys,
  [ACTIONS.ERROR_LOADING_ATTORNEYS]: errorLoadingAttorneys,
  [ACTIONS.SET_TASK_ATTRS]: setTaskAttrs,
  [ACTIONS.SET_APPEAL_ATTRS]: setAppealAttrs,
  [ACTIONS.SET_SPECIAL_ISSUE]: setSpecialIssue,
  [ACTIONS.CLEAR_SPECIAL_ISSUE]: clearSpecialIssue,
  [ACTIONS.SET_APPEAL_AOD]: setAppealAod,
  [ACTIONS.STARTED_LOADING_APPEAL_VALUE]: startedLoadingAppealValue,
  [ACTIONS.RECEIVE_APPEAL_VALUE]: receiveAppealValue,
  [ACTIONS.ERROR_ON_RECEIVE_APPEAL_VALUE]: errorOnReceiveAppealValue,
  [ACTIONS.SET_QUEUE_CONFIG]: setQueueConfig
});

const rootReducer = combineReducers({
  caseList: caseListReducer,
  caseSelect: caseSelectReducer,
  queue: workQueueReducer,
  teamManagement: teamManagementReducer,
  ui: uiReducer,
  components: commonComponentsReducer,
  docketSwitch: docketSwitchReducer,
  mtv: mtvReducer,
  substituteAppellant: substituteAppellantReducer,
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
