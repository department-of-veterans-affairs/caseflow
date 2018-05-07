import * as Constants from './actionTypes';

export const clearActiveCaseAndTask = () => ({
  type: Constants.CLEAR_ACTIVE_CASE_AND_TASK
});

export const setActiveCase = (caseObj) => ({
  type: Constants.SET_ACTIVE_CASE,
  payload: { caseObj }
});

export const setActiveTask = (taskObj) => ({
  type: Constants.SET_ACTIVE_TASK,
  payload: { taskObj }
});
