import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatDateStringForApi } from '../../util/DateUtil';
import _ from 'lodash';

const analytics = true;

export const submitReview = (intakeId, rampElection) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = {
    option_selected: rampElection.optionSelected,
    receipt_date: formatDateStringForApi(rampElection.receiptDate)
  };

  return ApiUtil.patch(`/intake/${intakeId}/review`, { data }, ENDPOINT_NAMES.REVIEW_INTAKE).
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

export const completeIntake = (intakeId, rampElection) => (dispatch) => {
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

  return ApiUtil.patch(`/intake/${intakeId}/complete`, {}, ENDPOINT_NAMES.COMPLETE_INTAKE).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_SUCCEED,
          payload: {
            intake: responseObject
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        let responseObject = {};

        try {
          responseObject = JSON.parse(error.response.text);
        } catch (ex) { /* pass */ }

        const responseErrorCode = responseObject.error_code;
        const responseErrorData = responseObject.error_data;

        dispatch({
          type: ACTIONS.COMPLETE_INTAKE_FAIL,
          payload: {
            responseErrorCode,
            responseErrorData
          },
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
