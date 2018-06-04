// @flow
import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './uiConstants';
import _ from 'lodash';

const initialSaveState = {
  savePending: false,
  saveSuccessful: null
};

export type UiState = {
  selectingJudge: boolean,
  breadcrumbs: Array<Object>,
  highlightFormItems: boolean,
  messages: {
    success: ?string,
    error: ?string
  },
  saveState: {
    savePending: boolean,
    saveSuccessful: ?boolean
  },
  modal: {
    cancelCheckout: boolean,
    deleteIssue: boolean
  },
  featureToggles: Object
};

export const initialState = {
  selectingJudge: false,
  breadcrumbs: [],
  highlightFormItems: false,
  messages: {
    success: null,
    error: null
  },
  saveState: initialSaveState,
  modal: {
    cancelCheckout: false,
    deleteIssue: false
  },
  featureToggles: {}
};

const setMessageState = (state, message, msgType) => update(state, {
  messages: {
    [msgType]: {
      $set: message
    }
  }
});

const setErrorMessageState = (state, message) => setMessageState(state, message, 'error');
const hideErrorMessage = (state) => setErrorMessageState(state, null);
const showErrorMessage = (state, errorMsg = 'Error') => setErrorMessageState(state, errorMsg);

const setSuccessMessageState = (state, message) => setMessageState(state, message, 'success');
const hideSuccessMessage = (state) => setSuccessMessageState(state, null);
const showSuccessMessage = (state, message = 'Success') => setSuccessMessageState(state, message);

const setModalState = (state, visibility, modalType) => update(state, {
  modal: {
    [modalType]: {
      $set: visibility
    }
  }
});

const showModal = (state, modalType) => setModalState(state, true, modalType);
const hideModal = (state, modalType) => setModalState(state, false, modalType);

const workQueueUiReducer = (state: UiState = initialState, action: Object = {}) => {
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
        $set: _.dropRight(state.breadcrumbs, action.payload.crumbsToDrop)
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
        error: { $set: null }
      }
    });
  case ACTIONS.RESET_SUCCESS_MESSAGES:
    return update(state, {
      messages: {
        success: { $set: null }
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
  case ACTIONS.SHOW_MODAL:
    return showModal(state, action.payload.modalType);
  case ACTIONS.HIDE_MODAL:
    return hideModal(state, action.payload.modalType);
  case ACTIONS.SET_FEATURE_TOGGLES:
    return update(state, {
      featureToggles: {
        $set: action.payload.featureToggles
      }
    });
  default:
    return state;
  }
};

export default workQueueUiReducer;
