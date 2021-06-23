import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';

const analytics = true;

export const startNewIntake = () => ({
  type: ACTIONS.START_NEW_INTAKE,
  meta: { analytics }
});

export const setFileNumberSearch = (fileNumber) => ({
  type: ACTIONS.SET_FILE_NUMBER_SEARCH,
  payload: {
    fileNumber
  }
});

export const doFileNumberSearch = (formType, fileNumberSearch) => (dispatch) => {
  dispatch({
    type: ACTIONS.FILE_NUMBER_SEARCH_START,
    meta: { analytics }
  });

  const data = {
    file_number: fileNumberSearch,
    form_type: formType
  };

  return ApiUtil.post('/intake', { data }, ENDPOINT_NAMES.START_INTAKE).
    then(
      (response) => {
        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_SUCCEED,
          payload: {
            intake: response.body
          },
          meta: { analytics }
        });
      },
      (error) => {
        const responseObject = error.response.body || {};
        const errorCode = responseObject.error_code || 'default';

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_FAIL,
          payload: {
            errorCode,
            errorData: responseObject.error_data || {}
          },
          meta: {
            analytics: {
              label: errorCode
            }
          }
        });

        throw error;
      }
    ).
    catch((error) => error);
};

export const setFormType = (formType) => ({
  type: ACTIONS.SET_FORM_TYPE,
  payload: {
    formType
  },
  meta: {
    analytics: {
      label: formType
    }
  }
});

export const clearSearchErrors = () => ({
  type: ACTIONS.CLEAR_SEARCH_ERRORS,
  meta: { analytics }
});

export const setReceiptDate = (receiptDate) => ({
  type: ACTIONS.SET_RECEIPT_DATE,
  payload: {
    receiptDate
  }
});

export const setReceiptDateError = (receiptDateError) => ({
  type: ACTIONS.SET_RECEIPT_DATE_ERROR,
  payload: {
    receiptDateError
  }
});

export const setOptionSelected = (optionSelected) => ({
  type: ACTIONS.SET_OPTION_SELECTED,
  payload: {
    optionSelected
  },
  meta: {
    analytics: {
      label: optionSelected
    }
  }
});

export const toggleCancelModal = () => ({
  type: ACTIONS.TOGGLE_CANCEL_MODAL,
  meta: {
    analytics: {
      label: (nextState) => nextState.intake.cancelModalVisible ? 'show' : 'hide'
    }
  }
});

export const submitCancel = (data) => (dispatch) => {
  dispatch({
    type: ACTIONS.CANCEL_INTAKE_START,
    meta: { analytics }
  });

  return ApiUtil.delete(`/intake/${data.id}`, { data }, ENDPOINT_NAMES.CANCEL_INTAKE).
    then(
      () => dispatch({
        type: ACTIONS.CANCEL_INTAKE_SUCCEED,
        meta: { analytics }
      }),
      (error) => {
        dispatch({
          type: ACTIONS.CANCEL_INTAKE_FAIL,
          meta: { analytics }
        });
        throw error;
      }
    ).
    catch((error) => error);
};

export const submitIntakeCompleteRequest = (intakeId, data) => (dispatch) => {
  return ApiUtil.patch(`/intake/${intakeId}/complete`, data, ENDPOINT_NAMES.COMPLETE_INTAKE).
    then(
      (response) => {
        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_SUCCEED,
          payload: {
            intake: response.body
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        const responseObject = error.response.body || {};
        const responseErrorCode = responseObject.error_code;
        const responseErrorData = responseObject.error_data;
        const responseErrorUUID = responseObject.error_uuid;

        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_FAIL,
          payload: {
            responseErrorCode,
            responseErrorData,
            responseErrorUUID
          },
          meta: { analytics }
        });
        throw error;
      }
    );
};

export const submitIntakeReviewRequest = (intakeId, data) => (dispatch) => {
  return ApiUtil.patch(`/intake/${intakeId}/review`, data, ENDPOINT_NAMES.REVIEW_INTAKE).
    then(
      () => dispatch({
        type: ACTIONS.SUBMIT_REVIEW_SUCCEED,
        meta: { analytics }
      }),
      (error) => {
        const responseObject = error.response.body || {};
        const responseErrorCodes = responseObject.error_codes;

        dispatch({
          type: ACTIONS.SUBMIT_REVIEW_FAIL,
          payload: {
            responseErrorCodes
          },
          meta: {
            analytics: analyticsCallback
          }
        });

        throw error;
      }
    );
};

export const analyticsCallback = (triggerEvent, category, actionName) => {
  triggerEvent(category, actionName, 'any-error');

  _.forEach(
    responseErrorCodes,
    (errorVal, errorKey) => triggerEvent(category, actionName, `${errorKey}-${errorVal}`)
  );
};
