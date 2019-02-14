// @flow
/* eslint-disable no-console */
import { ACTIONS } from './uiConstants';
import ApiUtil from '../../util/ApiUtil';

import type {
  UiStateMessage,
  Dispatch
} from '../types/state';

export const resetErrorMessages = () => ({
  type: ACTIONS.RESET_ERROR_MESSAGES
});

export const setCanEditAod = (canEditAod: Boolean) => ({
  type: ACTIONS.SET_CAN_EDIT_AOD,
  payload: {
    canEditAod
  }
});

export const showErrorMessage = (errorMessage: UiStateMessage) => ({
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

export const showSuccessMessage = (message: UiStateMessage) => ({
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

const saveSuccess = (message: UiStateMessage, response: Object) => (dispatch: Dispatch) => {
  dispatch(showSuccessMessage(message));
  dispatch({ type: ACTIONS.SAVE_SUCCESS });

  return Promise.resolve(response);
};

const saveFailure = (err: Object) => (dispatch: Dispatch) => {
  const { response } = err;
  let uiErrorMessage;

  try {
    uiErrorMessage = JSON.parse(response.text);
  } catch (ex) {
    // the default case if there is no `text` node in the response (ie the backend did not return sufficient info)
    uiErrorMessage = {
      errors: [{
        title: 'Error',
        detail: 'There was an error processing your request. ' +
        'Please retry your action and contact support if errors persist.'
      }]
    };
  }

  dispatch(showErrorMessage(uiErrorMessage.errors[0]));
  dispatch({ type: ACTIONS.SAVE_FAILURE });
  // the promise rejection below is also uncaught
  // but this seems to be by design since that's the same as the frontend handling and throwing an error

  return Promise.reject(new Error(response.text));
};

export const requestSave = (
  url: string, params: Object, successMessage: UiStateMessage, verb: string = 'post'
): Function => (dispatch: Dispatch) => {
  dispatch(hideErrorMessage());
  dispatch(hideSuccessMessage());

  dispatch({ type: ACTIONS.REQUEST_SAVE });

  return ApiUtil[verb](url, params).
    then(
      (resp) => dispatch(saveSuccess(successMessage, resp)),

    ).
    catch((err) => dispatch(saveFailure(err)));
};

export const requestPatch = (url: string, params: Object, successMessage: UiStateMessage) =>
  requestSave(url, params, successMessage, 'patch');
export const requestUpdate = (url: string, params: Object, successMessage: UiStateMessage) =>
  requestSave(url, params, successMessage, 'put');
export const requestDelete = (url: string, params: Object, successMessage: UiStateMessage) =>
  requestSave(url, params, successMessage, 'delete');

export const setSavePending = () => ({
  type: ACTIONS.REQUEST_SAVE
});

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

export const setUserCssId = (cssId: ?string) => ({
  type: ACTIONS.SET_USER_CSS_ID,
  payload: { cssId }
});

export const setOrganizations = (organizations: Array<Object>) => ({
  type: ACTIONS.SET_ORGANIZATIONS,
  payload: { organizations }
});

export const setActiveOrganization = (id: number, name: string, isVso: boolean) => ({
  type: ACTIONS.SET_ACTIVE_ORGANIZATION,
  payload: {
    id,
    name,
    isVso
  }
});

export const setUserId = (userId: number) => ({
  type: ACTIONS.SET_USER_ID,
  payload: { userId }
});

export const setUserIsVsoEmployee = (userIsVsoEmployee: ?boolean) => ({
  type: ACTIONS.SET_USER_IS_VSO_EMPLOYEE,
  payload: { userIsVsoEmployee }
});

export const setFeedbackUrl = (feedbackUrl: string) => ({
  type: ACTIONS.SET_FEEDBACK_URL,
  payload: { feedbackUrl }
});

type targetAssignee = { assigneeId: string };

export const setSelectedAssignee = ({ assigneeId }: targetAssignee) => ({
  type: ACTIONS.SET_SELECTED_ASSIGNEE,
  payload: {
    assigneeId
  }
});

export const setSelectedAssigneeSecondary = ({ assigneeId }: targetAssignee) => ({
  type: ACTIONS.SET_SELECTED_ASSIGNEE_SECONDARY,
  payload: {
    assigneeId
  }
});

export const toggleVeteranCaseList = () => ({
  type: ACTIONS.TOGGLE_VETERAN_CASE_LIST
});

export const showVeteranCaseList = () => ({
  type: ACTIONS.SHOW_VETERAN_CASE_LIST
});

export const hideVeteranCaseList = () => ({
  type: ACTIONS.HIDE_VETERAN_CASE_LIST
});

export const setHearingDay = (hearingDay: Object) => ({
  type: ACTIONS.SET_HEARING_DAY,
  payload: hearingDay
});
