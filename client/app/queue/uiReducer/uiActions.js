import { ACTIONS } from './uiConstants';
import ApiUtil from '../../util/ApiUtil';

export const resetErrorMessages = () => ({
  type: ACTIONS.RESET_ERROR_MESSAGES
});

export const showErrorMessage = (errorMessage) => ({
  type: ACTIONS.SHOW_ERROR_MESSAGE,
  payload: {
    errorMessage
  }
});

export const hideErrorMessage = () => ({
  type: ACTIONS.HIDE_ERROR_MESSAGE
});

export const resetSuccessMessages = () => ({
  type: ACTIONS.RESET_SUCCESS_MESSAGES
});

export const showSuccessMessage = (message) => ({
  type: ACTIONS.SHOW_SUCCESS_MESSAGE,
  payload: {
    message
  }
});

export const hideSuccessMessage = () => ({
  type: ACTIONS.HIDE_SUCCESS_MESSAGE
});

export const highlightInvalidFormItems = (highlight) => ({
  type: ACTIONS.HIGHLIGHT_INVALID_FORM_ITEMS,
  payload: {
    highlight
  }
});

export const setSelectingJudge = (selectingJudge) => ({
  type: ACTIONS.SET_SELECTING_JUDGE,
  payload: {
    selectingJudge
  }
});

export const pushBreadcrumb = (...crumbs) => ({
  type: ACTIONS.PUSH_BREADCRUMB,
  payload: {
    crumbs: [...crumbs]
  }
});

export const popBreadcrumb = (crumbsToDrop = 1) => ({
  type: ACTIONS.POP_BREADCRUMB,
  payload: {
    crumbsToDrop
  }
});

export const resetBreadcrumbs = () => ({
  type: ACTIONS.RESET_BREADCRUMBS
});

export const saveSuccess = (message, response) => (dispatch) => {
  dispatch(showSuccessMessage(message));
  dispatch({ type: ACTIONS.SAVE_SUCCESS });

  return Promise.resolve(response);
};

export const saveFailure = (resp) => (dispatch) => {
  const { response } = resp;
  let responseObject = {
    errors: [{
      title: 'Error',
      detail: 'There was an error processing your request.'
    }]
  };
  try {
    responseObject = JSON.parse(response.text);
  } catch (ex) { /* pass */ }

  dispatch(showErrorMessage(responseObject.errors[0]));
  dispatch({ type: ACTIONS.SAVE_FAILURE });

  return Promise.reject(responseObject.errors[0]);
};

export const requestSave = (url, params, successMessage, verb = 'post') => (dispatch) => {
  dispatch(hideErrorMessage());
  dispatch(hideSuccessMessage());
  dispatch({ type: ACTIONS.REQUEST_SAVE });

  return ApiUtil[verb](url, params).then(
    (response) => dispatch(saveSuccess(successMessage, response)),
    (resp) => dispatch(saveFailure(resp))
  );
};

export const requestUpdate = (url, params, successMessage) => requestSave(url, params, successMessage, 'put');
export const requestDelete = (url, params, successMessage) => requestSave(url, params, successMessage, 'delete');

export const resetSaveState = () => ({
  type: ACTIONS.RESET_SAVE_STATE
});

export const showModal = () => ({
  type: ACTIONS.SHOW_MODAL
});

export const hideModal = () => ({
  type: ACTIONS.HIDE_MODAL
});
