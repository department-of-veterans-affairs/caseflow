import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceConstants';

export const initialState = {
  taskRelatedAppealIds: [],
  newAppealRelatedTasks: [],
  fetchedAppeals: [],
  correspondences: [],
  radioValue: '0',
  relatedCorrespondences: [],
  mailTasks: [],
  unrelatedTasks: [],
  currentCorrespondence: [],
  veteranInformation: [],
  waivedEvidenceTasks: [],
  showReassignPackageModal: false,
  showRemovePackageModal: false,
};

export const intakeCorrespondenceReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.LOAD_CURRENT_CORRESPONDENCE:
    return update(state, {
      currentCorrespondence: {
        $set: action.payload.currentCorrespondence
      }
    });

  case ACTIONS.LOAD_CORRESPONDENCES:
    return update(state, {
      correspondences: {
        $set: action.payload.correspondences
      }
    });
  //will need to update all of the state for intakeCorrespondence
  case ACTIONS.LOAD_SAVED_INTAKE:
    return action.payload.savedStore;

  case ACTIONS.LOAD_VETERAN_INFORMATION:
    return update(state, {
      veteranInformation: {
        $set: action.payload.veteranInformation
      }
    });

  case ACTIONS.LOAD_VET_CORRESPONDENCE:
    return update(state, {
      vetCorrespondences: {
        $set: action.payload.vetCorrespondences
      }
    });

  case ACTIONS.LOAD_CORRESPONDENCE_CONFIG:
    return update(state, {
      correspondenceConfig: {
        $set: action.payload.correspondenceConfig
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
        $set: state.relatedCorrespondences.filter((corr) => corr.id !== action.payload.correspondence.id)
      }
    });

  case ACTIONS.CLEAR_CHECKBOX_STATE:
    return update(state, {
      relatedCorrespondences: {
        $set: []
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

  default:
    return state;
  }
};

export default intakeCorrespondenceReducer;
