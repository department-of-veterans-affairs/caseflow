import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatIssues } from '../../intake/util/issues';
import COPY from '../../../COPY';
import { PAGE_PATHS } from '../../intake/constants';
const analytics = true;

const pathMap = {
  higher_level_review: 'higher_level_reviews',
  supplemental_claim: 'supplemental_claims',
  appeal: 'appeals'
};

export const requestIssuesUpdate = (claimId, formType, state) => (dispatch) => {
  dispatch({
    type: ACTIONS.REQUEST_ISSUES_UPDATE_START,
    meta: { analytics }
  });

  const data = formatIssues(state);

  return ApiUtil.patch(`/${pathMap[formType]}/${claimId}/update`, { data }, ENDPOINT_NAMES.REQUEST_ISSUES_UPDATE).
    then(
      (response) => {
        dispatch({
          type: ACTIONS.REQUEST_ISSUES_UPDATE_SUCCEED,
          payload: {
            responseObject: response.body
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        const responseObject = error.response.body || {};
        const responseErrorCode = responseObject.error_code;

        dispatch({
          type: ACTIONS.REQUEST_ISSUES_UPDATE_FAIL,
          payload: {
            responseErrorCode
          },
          meta: { analytics }
        });
        throw error;
      }
    );
};

export const editEpClaimLabel = (claimId, formType, previousCode, selectedCode) => (dispatch) => {
  dispatch({
    type: ACTIONS.EDIT_EP_CLAIM_LABEL,
    payload: {
      previousCode,
      selectedCode,
    }
  });

  const data = {
    previous_code: previousCode,
    selected_code: selectedCode,
  };

  return ApiUtil.post(`/${pathMap[formType]}/${claimId}/edit_ep`, { data }, ENDPOINT_NAMES.EDIT_EP_CLAIM_LABEL).then(
    (response) => {

      if (response.statusCode === 200) {
        const alert = {
          type: 'success',
          title: COPY.EDIT_EP_CLAIM_LABEL_SUCCESS_ALERT_TITLE,
          detail: COPY.EDIT_EP_CLAIM_LABEL_SUCCESS_ALERT_MESSAGE
        };

        const veteranId = response.body.veteran.id;

        sessionStorage.setItem('veteranSearchPageAlert', JSON.stringify(alert));
        window.location.replace(`${PAGE_PATHS.SEARCH}?veteran_ids=${veteranId}`);
      }
    }, 
    (error) => {
      const responseObject = error.response.body || {};
      const responseErrorCode = responseObject.error_code;
      
        dispatch({
          type: ACTIONS.EDIT_EP_CLAIM_LABEL_FAILED,
          payload: {
           errorCode: responseErrorCode
          },
          meta: { analytics }
        });
      }

    ).catch((error) => error);
};
