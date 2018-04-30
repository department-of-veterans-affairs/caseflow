import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatDateStringForApi } from '../../util/DateUtil';
import _ from 'lodash';

const analytics = true;

export const setInformalConference = (informalConference) => ({
  type: ACTIONS.SET_INFORMAL_CONFERENCE,
  payload: {
    informalConference
  },
  meta: {
    analytics: {
      label: informalConference
    }
  }
});

export const setSameOffice = (sameOffice) => ({
  type: ACTIONS.SET_SAME_OFFICE,
  payload: {
    sameOffice
  },
  meta: {
    analytics: {
      label: sameOffice
    }
  }
});

export const submitReview = (intakeId, higherLevelReview) => (dispatch) => {
  dispatch({
    type: ACTIONS.SUBMIT_REVIEW_START,
    meta: { analytics }
  });

  const data = {
    informal_conference: higherLevelReview.informalConference,
    same_office: higherLevelReview.sameOffice,
    receipt_date: formatDateStringForApi(higherLevelReview.receiptDate)
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
