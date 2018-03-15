import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './uiConstants';

const initialErrorState = {
  decision: {
    visible: false,
    message: null
  }
};

export const initialState = {
  selectingJudge: false,
  breadcrumbs: [],
  highlightFormItems: false,
  errorState: initialErrorState,
  pendingSave: false,
  saveSuccessful: null
};

const setErrorMessageState = (state, errorType, isVisible, errorMsg = null) => update(state, {
  errorState: {
    [errorType]: {
      visible: { $set: isVisible },
      message: { $set: isVisible ? errorMsg : null }
    }
  }
});

const hideErrorMessage = (state, errorType, errorMsg = null) => setErrorMessageState(state, errorType, false, errorMsg);
const showErrorMessage = (state, errorType, errorMsg = null) => setErrorMessageState(state, errorType, true, errorMsg);

const workqueueUiReducer = (state = initialState, action = {}) => {
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
  case ACTIONS.REQUEST_SAVE_DECISION:
    return update(state, {
      pendingSave: { $set: true },
      saveSuccessful: { $set: null }
    });
  case ACTIONS.SAVE_DECISION_SUCCESS:
    return update(state, {
      pendingSave: { $set: false },
      saveSuccessful: { $set: true }
    });
  case ACTIONS.SAVE_DECISION_FAILURE:
    return update(state, {
      pendingSave: { $set: false },
      saveSuccessful: { $set: false }
    });
  case ACTIONS.RESET_ERROR_MESSAGES:
    return update(state, {
      errorState: { $set: initialErrorState }
    });
  case ACTIONS.HIDE_ERROR_MESSAGE:
    return hideErrorMessage(state, action.payload.messageType);
  case ACTIONS.SHOW_ERROR_MESSAGE:
    return showErrorMessage(state, action.payload.messageType, action.payload.errorMessage);
  default:
    return state;
  }
};

export default workqueueUiReducer;
