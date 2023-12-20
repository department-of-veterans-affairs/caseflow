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

export const getPoAValue = (taskId, endpoint) => (dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_LOADING_POWER_OF_ATTORNEY_VALUE,
    // payload: {
    //   appealId,
    //   name
    // }
  });
  ApiUtil.get(`/decision_reviews/vha/tasks/${taskId}/${endpoint}`).then((response) => {
    dispatch({
      type: ACTIONS.RECEIVED_POWER_OF_ATTORNEY,
      payload: {
        response: response.body
      }
    });
  }, (error) => {
    dispatch({
      type: ACTIONS.ERROR_ON_RECEIVE_POWER_OF_ATTORNEY_VALUE,
      payload: {
        error
      }
    });
  });
};

export const taskUpdateDefaultPage = (page) => (dispatch) => {
  dispatch({
    type: ACTIONS.TASK_DEFAULT_PAGE,
    payload: {
      currentTab: page
    }
  });
};

export const setPoaRefreshAlertDecisionReview = (alertType, message, powerOfAttorney) => ({
  type: ACTIONS.SET_POA_REFRESH_ALERT,
  payload: {
    alertType,
    message,
    powerOfAttorney
  }
});
