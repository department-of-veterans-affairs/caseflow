import { update } from '../../../util/ReducerUtil';
import { ACTIONS } from './correspondenceConstants';

export const initialState = {
  selectedAppeals: [],
  fetchedAppeals: [],
  correspondences: [],
  radioValue: '2',
  toggledCheckboxes: [],
  relatedTaskAppeals: [],
  unrelatedTasks: [],
  mailTasks: {}
};

export const intakeCorrespondenceReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.LOAD_CORRESPONDENCES:
    return update(state, {
      correspondences: {
        $set: action.payload.correspondences
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

  case ACTIONS.SET_RELATED_TASK_APPEALS:
    return update(state, {
      relatedTaskAppeals: {
        $set: [...action.payload.appeals]
      }
    });

  case ACTIONS.SET_UNRELATED_TASKS:
    return update(state, {
      unrelatedTasks: {
        $set: [...action.payload.tasks]
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

  case ACTIONS.SET_FETCHED_APPEALS:
    return update(state, {
      fetchedAppeals: {
        $set: [...action.payload.appeals]
      }
    });

  case ACTIONS.SAVE_APPEAL_CHECKBOX_STATE:
    return update(state, {
      selectedAppeals: {
        $set: [...action.payload.appealIds]
      }
    });

  case ACTIONS.CLEAR_APPEAL_CHECKBOX_STATE:
    return update(state, {
      selectedAppeals: {
        $set: []
      }
    });

  default:
    return state;
  }
};

export default intakeCorrespondenceReducer;
