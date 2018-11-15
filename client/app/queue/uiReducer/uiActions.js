// @flow
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

const saveFailure = (resp: Object) => (dispatch: Dispatch) => {
  const { response } = resp;
  let responseObject = {
    errors: [{
      title: 'Error',
      detail: 'There was an error processing your request. ' +
        'Please retry your action and contact support if errors persist.'
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
  url: string, params: Object, successMessage: UiStateMessage, verb: string = 'post'
): Function => (dispatch: Dispatch) => {
  dispatch(hideErrorMessage());
  dispatch(hideSuccessMessage());
  dispatch({ type: ACTIONS.REQUEST_SAVE });

  return ApiUtil[verb](url, params).then(
    (resp) => dispatch(saveSuccess(successMessage, resp)),
    (resp) => dispatch(saveFailure(resp))
  );
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

export const setOrganizationIds = (organizationIds: Array<number>) => ({
  type: ACTIONS.SET_ORGANIZATION_IDS,
  payload: { organizationIds }
});

export const setActiveOrganizationId = (activeOrganizationId: number) => ({
  type: ACTIONS.SET_ACTIVE_ORGANIZATION_ID,
  payload: { activeOrganizationId }
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

export const setHearingDay = ({ hearingDate, regionalOffice }) => ({
  type: ACTIONS.SET_HEARING_DAY,
  payload: {
    hearingDate, regionalOffice
  }
})
