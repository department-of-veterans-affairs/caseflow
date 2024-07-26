import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceConstants';

export const initialState = {
  taskRelatedAppealIds: [],
  newAppealRelatedTasks: [],
  fetchedAppeals: [],
  radioValue: '0',
  relatedCorrespondences: [],
  selectedTasks: [],
  mailTasks: [],
  unrelatedTasks: [],
  waivedEvidenceTasks: [],
  responseLetters: {},
  correspondenceInformation: {},
  selectedVeteranDetails: {},
  showReassignPackageModal: false,
  showRemovePackageModal: false,
  showErrorBanner: false
};

export const intakeCorrespondenceReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.LOAD_SAVED_INTAKE:
    return action.payload.savedStore;

  case ACTIONS.SAVE_CURRENT_INTAKE:
    return action.payload.currentIntake;

  case ACTIONS.LOAD_VET_CORRESPONDENCE:
    return update(state, {
      vetCorrespondences: {
        $set: action.payload.vetCorrespondences
      }
    });

  case ACTIONS.LOAD_CORRESPONDENCE:
    return update(state, {
      correspondence: {
        $set: action.payload.correspondence
      }
    });

  case ACTIONS.LOAD_CORRESPONDENCE_CONFIG:
    return update(state, {
      correspondenceConfig: {
        $set: action.payload.correspondenceConfig
      }
    });

  case ACTIONS.LOAD_INBOUND_OPS_TEAM_USERS:
    return update(state, {
      inboundOpsTeamUsers: {
        $set: action.payload.inboundOpsTeamUsers
      }
    });

  case ACTIONS.UPDATE_RADIO_VALUE:
    return update(state, {
      radioValue: {
        $set: action.payload.radioValue
      }
    });

  case ACTIONS.SAVE_CHECKBOX_STATE:
    if (action.payload.isChecked) {
      return update(state, {
        relatedCorrespondences: {
          $push: [action.payload.correspondence]
        }
      });
    }

    return update(state, {
      relatedCorrespondences: {
        $set: state.relatedCorrespondences.filter((corr) => corr.uuid !== action.payload.correspondence.uuid)
      }
    });

  case ACTIONS.CLEAR_CHECKBOX_STATE:
    return update(state, {
      relatedCorrespondences: {
        $set: []
      }
    });

    // fix this to use the actual value for set
  case ACTIONS.SET_SELECTED_TASKS:
    return update(state, {
      selectedTasks: {
        $set: [...action.payload.values]
      }
    });

  case ACTIONS.SET_UNRELATED_TASKS:
    return update(state, {
      unrelatedTasks: {
        $set: [...action.payload.tasks]
      }
    });

  case ACTIONS.SET_FETCHED_APPEALS:
    return update(state, {
      fetchedAppeals: {
        $set: [...action.payload.appeals]
      }
    });

  case ACTIONS.SAVE_MAIL_TASK_STATE:
    return update(state, {
      mailTasks: {
        $set: [...action.payload.name]
      }
    });

  case ACTIONS.SET_TASK_RELATED_APPEAL_IDS:
    return update(state, {
      taskRelatedAppealIds: {
        $set: [...action.payload.appealIds]
      }
    });

  case ACTIONS.SET_NEW_APPEAL_RELATED_TASKS:
    return update(state, {
      newAppealRelatedTasks: {
        $set: [...action.payload.newAppealRelatedTasks]
      }
    });

  case ACTIONS.SET_WAIVED_EVIDENCE_TASKS:
    return update(state, {
      waivedEvidenceTasks: {
        $set: [...action.payload.task]
      }
    });

  case ACTIONS.SET_RESPONSE_LETTERS:
    return update(state, {
      responseLetters: {
        $merge: action.payload.responseLetters
      }
    });

  case ACTIONS.REMOVE_RESPONSE_LETTERS:
    const newResponseLetters = state.responseLetters;

    delete newResponseLetters[action.payload.index];

    return update(state, {
      responseLetters: {
        $set: newResponseLetters
      }
    });

  case ACTIONS.SET_SHOW_REASSIGN_PACKAGE_MODAL:
    return update(state, {
      showReassignPackageModal: {
        $set: action.payload.isVisible
      }
    });

  case ACTIONS.SET_SHOW_REMOVE_PACKAGE_MODAL:
    return update(state, {
      showRemovePackageModal: {
        $set: action.payload.isVisible
      }
    });

  case ACTIONS.SET_SELECTED_VETERAN_DETAILS:
    return update(state, {
      selectedVeteranDetails: {
        $set: action.payload.selectedVeteranDetails
      }
    });

  case ACTIONS.SET_SHOW_CORRESPONDENCE_INTAKE_FORM_ERROR_BANNER:
    return update(state, {
      showErrorBanner: {
        $set: action.payload.isVisible
      }
    });

  default:
    return state;
  }
};

export default intakeCorrespondenceReducer;
