import * as Constants from './actionTypes';

export const clearActiveCase = () => ({
  type: Constants.CLEAR_ACTIVE_CASE
});

export const setActiveCase = (caseObj) => ({
  type: Constants.SET_ACTIVE_CASE,
  payload: { caseObj }
});
