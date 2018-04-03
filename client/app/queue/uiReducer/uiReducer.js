import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './uiConstants';
import _ from 'lodash';

const initialMessageState = {
  visible: false,
  message: null
};

const initialSaveState = {
  savePending: false,
  saveSuccessful: null
};

export const initialState = {
  selectingJudge: false,
  breadcrumbs: [],
  highlightFormItems: false,
  messages: {
    success: initialMessageState,
    error: initialMessageState
  },
  saveState: initialSaveState
};

const setMessageState = (state, isVisible, message, msgType) => update(state, {
  messages: {
    [msgType]: {
      visible: { $set: isVisible },
      message: { $set: message }
    }
  }
});

const setErrorMessageState = (state, isVisible, message) => setMessageState(state, isVisible, message, 'error');
const hideErrorMessage = (state) => setErrorMessageState(state, false);
const showErrorMessage = (state, errorMsg = null) => setErrorMessageState(state, true, errorMsg);

const setSuccessMessageState = (state, isVisible, message) => setMessageState(state, isVisible, message, 'success');
const hideSuccessMessage = (state) => setSuccessMessageState(state, false);
const showSuccessMessage = (state, message) => setSuccessMessageState(state, true, message);

const workQueueUiReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case ACTIONS.SET_SELECTING_JUDGE:
    return update(state, {
      selectingJudge: { $set: action.payload.selectingJudge }
    });
  case ACTIONS.PUSH_BREADCRUMB:
    return update(state, {
      breadcrumbs: {
        $push: action.payload.crumbs
      }
    });
  case ACTIONS.POP_BREADCRUMB:
    return update(state, {
      breadcrumbs: {
        $set: _.dropRight(state.breadcrumbs, 1)
      }
    });
  case ACTIONS.RESET_BREADCRUMBS:
    return update(state, {
      breadcrumbs: {
        $set: []
      }
    });
  case ACTIONS.HIGHLIGHT_INVALID_FORM_ITEMS:
    return update(state, {
      highlightFormItems: {
        $set: action.payload.highlight
      }
    });
  case ACTIONS.REQUEST_SAVE:
    return update(state, {
      saveState: {
        savePending: { $set: true },
        saveSuccessful: { $set: null }
      }
    });
  case ACTIONS.SAVE_SUCCESS:
    return update(state, {
      saveState: {
        savePending: { $set: false },
        saveSuccessful: { $set: true }
      }
    });
  case ACTIONS.SAVE_FAILURE:
    return update(state, {
      saveState: {
        savePending: { $set: false },
        saveSuccessful: { $set: false }
      }
    });
  case ACTIONS.RESET_SAVE_STATE:
    return update(state, {
      saveState: { $set: initialSaveState }
    });
  case ACTIONS.RESET_ERROR_MESSAGES:
    return update(state, {
      messages: {
        error: { $set: initialMessageState }
      }
    });
  case ACTIONS.RESET_SUCCESS_MESSAGES:
    return update(state, {
      messages: {
        success: { $set: initialMessageState }
      }
    });
  case ACTIONS.HIDE_ERROR_MESSAGE:
    return hideErrorMessage(state);
  case ACTIONS.SHOW_ERROR_MESSAGE:
    return showErrorMessage(state, action.payload.errorMessage);
  case ACTIONS.SHOW_SUCCESS_MESSAGE:
    return showSuccessMessage(state, action.payload.message);
  case ACTIONS.HIDE_SUCCESS_MESSAGE:
    return hideSuccessMessage(state);
  default:
    return state;
  }
};

export default workQueueUiReducer;
