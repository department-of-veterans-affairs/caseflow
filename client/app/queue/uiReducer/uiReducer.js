import { update } from '../../util/ReducerUtil';
import { ACTIONS } from './uiConstants';
import _ from 'lodash';

const initialErrorState = {
  visible: false,
  message: null
};

export const initialState = {
  selectingJudge: false,
  breadcrumbs: [],
  footerButtons: [],
  highlightFormItems: false,
  errorState: initialErrorState,
  savePending: false,
  saveSuccessful: null
};

const setErrorMessageState = (state, isVisible, errorMsg = null) => update(state, {
  errorState: {
    visible: { $set: isVisible },
    message: { $set: isVisible ? errorMsg : null }
  }
});

const hideErrorMessage = (state) => setErrorMessageState(state, false);
const showErrorMessage = (state, errorMsg = null) => setErrorMessageState(state, true, errorMsg);

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
  case ACTIONS.SET_FOOTER_BUTTONS:
    return update(state, {
      footerButtons: {
        $set: action.payload.buttons
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
      savePending: { $set: true },
      saveSuccessful: { $set: null }
    });
  case ACTIONS.SAVE_SUCCESS:
    return update(state, {
      savePending: { $set: false },
      saveSuccessful: { $set: true }
    });
  case ACTIONS.SAVE_FAILURE:
    return update(state, {
      savePending: { $set: false },
      saveSuccessful: { $set: false }
    });
  case ACTIONS.RESET_ERROR_MESSAGES:
    return update(state, {
      errorState: { $set: initialErrorState }
    });
  case ACTIONS.HIDE_ERROR_MESSAGE:
    return hideErrorMessage(state);
  case ACTIONS.SHOW_ERROR_MESSAGE:
    return showErrorMessage(state, action.payload.errorMessage);
  default:
    return state;
  }
};

export default workQueueUiReducer;
