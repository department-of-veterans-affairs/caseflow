import { ACTIONS } from './reviewPackageConstants';

export const setCorrespondence = (correspondence) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_CORRESPONDENCE,
      payload: {
        correspondence
      }
    });
  };

export const setCreateRecordIsReadOnly = (createRecordIsReadOnly) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.CREATE_RECORD_IS_READ_ONLY,
      payload: {
        createRecordIsReadOnly
      }
    });
  };

export const updateCmpInformation = (packageDocumentType, date) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_CMP_INFORMATION,
      payload: {
        packageDocumentType,
        date
      }
    });
  };

export const updateDocumentTypeName = (newName, index) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.UPDATE_DOCUMENT_TYPE_NAME,
      payload: {
        newName,
        index
      }
    });
  };

export const updateLastAction = (currentAction) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REMOVE_PACKAGE_ACTION,
      payload: {
        currentAction
      }
    });
  };

export const setTaskInstructions = (taskInstructions) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_TASK_INSTRUCTIONS,
      payload: {
        taskInstructions
      }
    });
  };

export const setBatchAutoAssignmentAttemptId = (batchId) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_BATCH_AUTO_ASSIGN_ATTEMPT_ID,
      payload: {
        batchId
      }
    });
  };

export const updateLastReassignAction = (currentAction) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.REASSIGN_PACKAGE_ACTION,
      payload: {
        currentAction
      }
    });
  };

export const setAutoAssignmentAlertBanner = (bannerDetails) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_AUTO_ASSIGN_BANNER,
      payload: {
        title: bannerDetails.title,
        message: bannerDetails.message,
        type: bannerDetails.type
      }
    });
  };

export const setAutoAssignButtonDisabled = (isButtonDisabled) =>
  (dispatch) => {
    dispatch({
      type: ACTIONS.SET_AUTO_ASSIGN_BUTTON_DISABLED,
      payload: {
        isButtonDisabled
      }
    });
  };
