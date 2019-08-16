import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatIssues } from '../../intake/util/issues';

const analytics = true;

export const requestIssuesUpdate = (claimId, formType, state) => (dispatch) => {
  dispatch({
    type: ACTIONS.REQUEST_ISSUES_UPDATE_START,
    meta: { analytics }
  });

  const data = formatIssues(state);

  const pathMap = {
    higher_level_review: 'higher_level_reviews',
    supplemental_claim: 'supplemental_claims',
    appeal: 'appeals'
  };

  return ApiUtil.patch(`/${pathMap[formType]}/${claimId}/update`, { data }, ENDPOINT_NAMES.REQUEST_ISSUES_UPDATE).
    then(
      (response) => {
        dispatch({
          type: ACTIONS.REQUEST_ISSUES_UPDATE_SUCCEED,
          payload: {
            response.body
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
