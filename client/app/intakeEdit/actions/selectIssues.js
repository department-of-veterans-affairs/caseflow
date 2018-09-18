import { ACTIONS, ENDPOINT_NAMES } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { formatIssues } from '../../intakeCommon/util';

const analytics = true;

export const requestIssuesUpdate = (claimId, state) => (dispatch) => {
  dispatch({
    type: ACTIONS.REQUEST_ISSUES_UPDATE_START,
    meta: { analytics }
  });

  const data = formatIssues(state);

  return ApiUtil.patch(`/higher_level_reviews/${claimId}/update_issues`, { data }, ENDPOINT_NAMES.REQUEST_ISSUES_UPDATE)
    .then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.REQUEST_ISSUES_UPDATE_SUCCEED,
          payload: {
            ratings: responseObject.ratings,
            ratedRequestIssues: responseObject.ratedRequestIssues
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
          type: ACTIONS.REQUEST_ISSUES_UPDATE_FAIL,
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
