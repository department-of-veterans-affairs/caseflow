import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';

const analytics = true;

export const taskUpdateDecisionIssues = (taskId, businessLine, data, veteran) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_START,
    meta: { analytics }
  });

  return ApiUtil.put(`/decision_reviews/${businessLine}/tasks/${taskId}`, data, 'decision-issues-update').
    then(
      () => {
        dispatch({
          type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_SUCCEED,
          payload: {
            veteran,
            completedTaskId: taskId
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
};

export const taskUpdateDefaultPage = (page) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASK_DEFAULT_PAGE,
    payload: {
      currentTab: page
    }
  });
};

