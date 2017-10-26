import { ACTIONS } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatDateStringForApi } from '../../util/DateUtil';
import _ from 'lodash';

const analytics = true;

const ENDPOINT_NAMES = {
  INTAKE: 'intake',
  INTAKE_RAMP: 'intake-ramp',
  INTAKE_RAMP_COMPLETE: 'intake-ramp-complete'
};

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

export const doFileNumberSearch = (fileNumberSearch) => (dispatch) => {
  dispatch({
    type: ACTIONS.FILE_NUMBER_SEARCH_START,
    meta: { analytics }
  });

  return ApiUtil.post('/intake', { data: { file_number: fileNumberSearch } }, ENDPOINT_NAMES.INTAKE).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.FILE_NUMBER_SEARCH_SUCCEED,
          payload: {
            intake: responseObject
          },
          meta: { analytics }
        });
      },
      (error) => {
        const responseObject = JSON.parse(error.response.text);
        const errorCode = responseObject.error_code;

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
    );
};

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

export const setReceiptDate = (receiptDate) => ({
  type: ACTIONS.SET_RECEIPT_DATE,
  payload: {
    receiptDate
  }
});

export const submitReview = (rampElection) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = {
    option_selected: rampElection.optionSelected,
    receipt_date: formatDateStringForApi(rampElection.receiptDate)
  };

  return ApiUtil.patch(`/intake/ramp/${rampElection.intakeId}`, { data }, ENDPOINT_NAMES.INTAKE_RAMP).
    then(
      () => dispatch({
        type: ACTIONS.SUBMIT_REVIEW_SUCCEED,
        meta: { analytics }
      }),
      (error) => {
        const responseObject = JSON.parse(error.response.text);
        const responseErrorCodes = responseObject.error_codes;

        dispatch({
          type: ACTIONS.SUBMIT_REVIEW_FAIL,
          payload: {
            responseErrorCodes
          },
          meta: {
            analytics: (triggerEvent, category, actionName) => {
              triggerEvent(category, actionName, 'any-error');

              _.forEach(
                responseErrorCodes,
                (errorVal, errorKey) => triggerEvent(category, actionName, `${errorKey}-${errorVal}`)
              );
            }
          }
        });

        throw error;
      }
    );
};

export const completeIntake = (rampElection) => (dispatch) => {
  if (!rampElection.finishConfirmed) {
    dispatch({
      type: ACTIONS.COMPLETE_INTAKE_NOT_CONFIRMED,
      meta: { analytics }
    });

    return Promise.resolve(false);
  }

  dispatch({
    type: ACTIONS.COMPLETE_INTAKE_START,
    meta: { analytics }
  });

  return ApiUtil.patch(`/intake/ramp/${rampElection.intakeId}/complete`, {}, ENDPOINT_NAMES.INTAKE_RAMP_COMPLETE).
    then(
      () => {
        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_SUCCEED,
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_FAIL,
          meta: { analytics }
        });
        throw error;
      }
    );
};

export const toggleCancelModal = () => ({
  type: ACTIONS.TOGGLE_CANCEL_MODAL,
  meta: {
    analytics: {
      label: (nextState) => nextState.cancelModalVisible ? 'show' : 'hide'
    }
  }
});

export const submitCancel = (rampElection) => (dispatch) => {
  dispatch({
    type: ACTIONS.CANCEL_INTAKE_START,
    meta: { analytics }
  });

  return ApiUtil.delete(`/intake/ramp/${rampElection.intakeId}`, {}, ENDPOINT_NAMES.INTAKE_RAMP).
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
    );
};

export const confirmFinishIntake = (isConfirmed) => ({
  type: ACTIONS.CONFIRM_FINISH_INTAKE,
  payload: { isConfirmed },
  meta: {
    analytics: {
      label: isConfirmed ? 'confirmed' : 'not-confirmed'
    }
  }
});
