import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceConstants';

export const initialState = {
  taskRelatedAppealIds: [],
  fetchedAppeals: [],
  correspondences: [],
  radioValue: '2',
  toggledCheckboxes: [],
  mailTasks: {},
  unrelatedTasks: [],
  currentCorrespondence: [],
  veteranInformation: []
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

  case ACTIONS.UPDATE_RADIO_VALUE:
    return update(state, {
      radioValue: {
        $set: action.payload.radioValue
      }
    });

  case ACTIONS.SAVE_CHECKBOX_STATE:
    if (action.payload.isChecked) {
      return update(state, {
        toggledCheckboxes: {
          $push: [action.payload.id]
        }
      });
    }

    return update(state, {
      toggledCheckboxes: {
        $set: state.toggledCheckboxes.filter((id) => id !== action.payload.id)
      }
    });

  case ACTIONS.CLEAR_CHECKBOX_STATE:
    return update(state, {
      toggledCheckboxes: {
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
        [action.payload.name]: {
          $set: action.payload.isChecked
        }
      }
    });

  case ACTIONS.SET_TASK_RELATED_APPEAL_IDS:
    return update(state, {
      taskRelatedAppealIds: {
        $set: [...action.payload.appealIds]
      }
    });

  default:
    return state;
  }
};

export default intakeCorrespondenceReducer;
