import ApiUtil from '../../util/ApiUtil';
import { ACTIONS } from '../constants';
import { formatTasks } from '../util';

const analytics = true;

export const completeTask = (taskId, businessLine, data, claimant) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_START,
    meta: { analytics }
  });

  return ApiUtil.put(`/decision_reviews/${businessLine}/tasks/${taskId}`, data, 'decision-issues-update').
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: ACTIONS.TASK_UPDATE_DECISION_ISSUES_SUCCEED,
          payload: {
            claimant,
            completedTaskId: taskId,
            inProgressTasks: formatTasks(responseObject.in_progress_tasks),
            completedTasks: formatTasks(responseObject.completed_tasks)
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

