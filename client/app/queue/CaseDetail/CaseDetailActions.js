import * as Constants from './actionTypes';

export const clearActiveAppealAndTask = () => ({
  type: Constants.CLEAR_ACTIVE_APPEAL_AND_TASK
});

export const setActiveAppeal = (appeal) => ({
  type: Constants.SET_ACTIVE_APPEAL,
  payload: { appeal }
});

export const setActiveTask = (taskObj) => ({
  type: Constants.SET_ACTIVE_TASK,
  payload: { taskObj }
});
