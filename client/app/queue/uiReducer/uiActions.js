// @flow
import { ACTIONS } from './uiConstants';
import ApiUtil from '../../util/ApiUtil';
import _ from 'lodash';

import type { Dispatch } from '../types/state';

export const resetErrorMessages = () => ({
  type: ACTIONS.RESET_ERROR_MESSAGES
});

export const showErrorMessage = (errorMessage: Object) => ({
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

export const showSuccessMessage = (message: Object | string) => ({
  type: ACTIONS.SHOW_SUCCESS_MESSAGE,
  payload: {
    message
  }
});

export const hideSuccessMessage = () => ({
  type: ACTIONS.HIDE_SUCCESS_MESSAGE
});

export const highlightInvalidFormItems = (highlight: boolean) => ({
  type: ACTIONS.HIGHLIGHT_INVALID_FORM_ITEMS,
  payload: {
    highlight
  }
});

export const setSelectingJudge = (selectingJudge: boolean) => ({
  type: ACTIONS.SET_SELECTING_JUDGE,
  payload: {
    selectingJudge
  }
});

const saveSuccess = (message: Object | string, response: Object) => (dispatch: Dispatch) => {
  dispatch(showSuccessMessage(_.isObject(message) ? message : { title: message }));
  dispatch({ type: ACTIONS.SAVE_SUCCESS });

  return Promise.resolve(response);
};

const saveFailure = (resp: Object) => (dispatch: Dispatch) => {
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

export const requestSave = (
  url: string, params: Object, successMessage: Object | string, verb: string = 'post'
): Function => (dispatch: Dispatch) => {
  dispatch(hideErrorMessage());
  dispatch(hideSuccessMessage());
  dispatch({ type: ACTIONS.REQUEST_SAVE });

  return ApiUtil[verb](url, params).then(
    (resp) => dispatch(saveSuccess(successMessage, resp)),
    (resp) => dispatch(saveFailure(resp))
  );
};

export const requestUpdate = (url: string, params: Object, successMessage: Object | string) =>
  requestSave(url, params, successMessage, 'put');
export const requestDelete = (url: string, params: Object, successMessage: Object | string) =>
  requestSave(url, params, successMessage, 'delete');

export const resetSaveState = () => ({
  type: ACTIONS.RESET_SAVE_STATE
});

export const showModal = (modalType: string) => ({
  type: ACTIONS.SHOW_MODAL,
  payload: { modalType }
});

export const hideModal = (modalType: string) => ({
  type: ACTIONS.HIDE_MODAL,
  payload: { modalType }
});

export const setFeatureToggles = (featureToggles: Object) => ({
  type: ACTIONS.SET_FEATURE_TOGGLES,
  payload: { featureToggles }
});

export const setUserRole = (userRole: string) => ({
  type: ACTIONS.SET_USER_ROLE,
  payload: { userRole }
});

export const setUserCssId = (cssId: string) => ({
  type: ACTIONS.SET_USER_CSS_ID,
  payload: { cssId }
});

export const setSelectedAssignee = ({ assigneeId }: Object) => ({
  type: ACTIONS.SET_SELECTED_ASSIGNEE,
  payload: {
    assigneeId
  }
});

export const setSelectedAssigneeSecondary = ({ assigneeId }: Object) => ({
  type: ACTIONS.SET_SELECTED_ASSIGNEE_SECONDARY,
  payload: {
    assigneeId
  }
});
