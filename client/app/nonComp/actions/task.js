import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';

const analytics = true;

export const taskUpdateDecisionIssues = (taskId, businessLine, decisionIssues) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_START,
    meta: { analytics }
  });

  // const data = formatDecisionIssues(decisionIssues);

  // /decision_reviews/:decision_review_business_line_slug/tasks/:task_id
  return ApiUtil.put(`/decision_reviews/${businessLine}/tasks/${taskId}`, { decisionIssues }, 'decision-issues-update').
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_SUCCEED,
          payload: {
            decisionIssues: responseObject.decisionIssues
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

        dispatch({
          type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_FAIL,
          payload: {
            responseErrorCode
          },
          meta: { analytics }
        });
        throw error;
      }
    );
}
