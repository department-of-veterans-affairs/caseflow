import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';

const analytics = true;

export const completeTask = (taskId, businessLine, data, claimant) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_START,
    meta: { analytics }
  });

  return ApiUtil.put(`/decision_reviews/${businessLine}/tasks/${taskId}`, data, 'decision-issues-update').
    then(
      (response) => {
        dispatch({
          type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_SUCCEED,
          payload: {
            claimant,
            completedTaskId: taskId,
            taskFilterDetails: response.body.task_filter_details
          },
          meta: { analytics }
        });

        return true;
      },
      (error) => {
        const responseObject = error.response.body || {};
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

