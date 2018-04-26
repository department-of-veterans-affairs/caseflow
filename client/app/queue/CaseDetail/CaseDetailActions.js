import * as Constants from './actionTypes';

export const clearActiveCase = () => ({
  type: Constants.CLEAR_ACTIVE_CASE
});

export const setActiveCase = (caseObj) => ({
  type: Constants.SET_ACTIVE_CASE,
  payload: { caseObj }
});

export const setDocumentCount = (docCount) => ({
  type: Constants.SET_ACTIVE_CASE_DOCUMENT_COUNT,
  payload: { docCount }
});

