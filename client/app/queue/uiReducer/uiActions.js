/* eslint-disable no-console */
import { ACTIONS } from './uiConstants';
import ApiUtil from '../../util/ApiUtil';

export const resetErrorMessages = () => ({
  type: ACTIONS.RESET_ERROR_MESSAGES
});

export const setCanEditAod = (canEditAod) => ({
  type: ACTIONS.SET_CAN_EDIT_AOD,
  payload: {
    canEditAod
  }
});

export const setCanEditCavcRemands = (canEditCavcRemands) => ({
  type: ACTIONS.SET_CAN_EDIT_CAVC_REMANDS,
  payload: {
    canEditCavcRemands
  }
});

export const setCanEditNodDate = (canEditNodDate) => ({
  type: ACTIONS.SET_CAN_EDIT_NOD_DATE,
  payload: {
    canEditNodDate
  }
});

export const setUserIsCobAdmin = (userIsCobAdmin) => ({
  type: ACTIONS.SET_USER_IS_COB_ADMIN,
  payload: {
    userIsCobAdmin
  }
});

export const setCanViewOvertimeStatus = (canViewOvertimeStatus) => ({
  type: ACTIONS.SET_CAN_VIEW_OVERTIME_STATUS,
  payload: {
    canViewOvertimeStatus
  }
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

export const setPoaRefreshAlert = (alertType, message, powerOfAttorney) => ({
  type: ACTIONS.SET_POA_REFRESH_ALERT,
  payload: {
    alertType,
    message,
    powerOfAttorney
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

const saveSuccess = (message, response) => (dispatch) => {
  dispatch(showSuccessMessage(message));
  dispatch({ type: ACTIONS.SAVE_SUCCESS });

  return Promise.resolve(response);
};

const saveFailure = (err) => (dispatch) => {
  const { response } = err;
  let uiErrorMessage;

  try {
    uiErrorMessage = response.body.errors[0];
  } catch (ex) {
    // the default case if there is no `text` node in the response (ie the backend did not return sufficient info)
    uiErrorMessage = {
      title: 'Error',
      detail: 'There was an error processing your request. ' +
      'Please retry your action and contact support if errors persist.'
    };
  }

  dispatch(showErrorMessage(uiErrorMessage));
  dispatch({ type: ACTIONS.SAVE_FAILURE });
  // the promise rejection below is also uncaught
  // but this seems to be by design since that's the same as the frontend handling and throwing an error

  return Promise.reject(response.text);
};

export const requestSave = (
  url, params, successMessage, verb = 'post'
) => (dispatch) => {
  dispatch(hideErrorMessage());
  dispatch(hideSuccessMessage());

  dispatch({ type: ACTIONS.REQUEST_SAVE });

  return ApiUtil[verb](url, params).
    then(
      (resp) => dispatch(saveSuccess(successMessage, resp)),

    ).
    catch((err) => dispatch(saveFailure(err)));
};

export const requestGet = (url, params, successMessage) =>
  requestSave(url, params, successMessage, 'get');
export const requestPatch = (url, params, successMessage) =>
  requestSave(url, params, successMessage, 'patch');
export const requestUpdate = (url, params, successMessage) =>
  requestSave(url, params, successMessage, 'put');
export const requestDelete = (url, params, successMessage) =>
  requestSave(url, params, successMessage, 'delete');

export const setSavePending = () => ({
  type: ACTIONS.REQUEST_SAVE
});

export const resetSaveState = () => ({
  type: ACTIONS.RESET_SAVE_STATE
});

export const showModal = (modalType) => ({
  type: ACTIONS.SHOW_MODAL,
  payload: { modalType }
});

export const hideModal = (modalType) => ({
  type: ACTIONS.HIDE_MODAL,
  payload: { modalType }
});

export const setFeatureToggles = (featureToggles) => ({
  type: ACTIONS.SET_FEATURE_TOGGLES,
  payload: { featureToggles }
});

export const setUserRole = (userRole) => ({
  type: ACTIONS.SET_USER_ROLE,
  payload: { userRole }
});

export const setUserCssId = (cssId) => ({
  type: ACTIONS.SET_USER_CSS_ID,
  payload: { cssId }
});

export const setOrganizations = (organizations) => ({
  type: ACTIONS.SET_ORGANIZATIONS,
  payload: { organizations }
});

export const setActiveOrganization = (id, name, isVso, userCanBulkAssign) => ({
  type: ACTIONS.SET_ACTIVE_ORGANIZATION,
  payload: {
    id,
    name,
    isVso,
    userCanBulkAssign
  }
});

export const setUserId = (userId) => ({
  type: ACTIONS.SET_USER_ID,
  payload: { userId }
});

export const setTargetUser = (targetUser) => ({
  type: ACTIONS.SET_TARGET_USER,
  payload: { targetUser }
});

export const setUserIsVsoEmployee = (userIsVsoEmployee) => ({
  type: ACTIONS.SET_USER_IS_VSO_EMPLOYEE,
  payload: { userIsVsoEmployee }
});

export const setFeedbackUrl = (feedbackUrl) => ({
  type: ACTIONS.SET_FEEDBACK_URL,
  payload: { feedbackUrl }
});

export const setSelectedAssignee = ({ assigneeId }) => ({
  type: ACTIONS.SET_SELECTED_ASSIGNEE,
  payload: {
    assigneeId
  }
});

export const setSelectedAssigneeSecondary = ({ assigneeId }) => ({
  type: ACTIONS.SET_SELECTED_ASSIGNEE_SECONDARY,
  payload: {
    assigneeId
  }
});

export const resetAssignees = () => ({
  type: ACTIONS.RESET_ASSIGNEES
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

export const setHearingDay = (hearingDay) => ({
  type: ACTIONS.SET_HEARING_DAY,
  payload: hearingDay
});
