import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatDateStringForApi } from '../../util/DateUtil';
import _ from 'lodash';

const analytics = true;

export const setReceiptDate = (receiptDate) => ({
  type: ACTIONS.SET_RECEIPT_DATE,
  payload: {
    receiptDate
  }
});

export const submitReview = (intakeId, supplementalClaim) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = {
    receipt_date: formatDateStringForApi(supplementalClaim.receiptDate)
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

export const setIssueSelected = (profileDate, issueId, isSelected) => ({
  type: ACTIONS.SET_ISSUE_SELECTED,
  payload: {
    profileDate,
    issueId,
    isSelected
  },
  meta: {
    analytics: {
      label: isSelected ? 'selected' : 'de-selected'
    }
  }
});
