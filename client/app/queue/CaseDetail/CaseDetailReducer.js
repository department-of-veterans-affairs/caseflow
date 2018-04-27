import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  activeCase: null,
  documentCount: null
};

export const caseDetailReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_ACTIVE_CASE:
    return initialState;
  case Constants.SET_ACTIVE_CASE:
    return update(state, {
      activeCase: { $set: action.payload.caseObj }
    });
  case Constants.SET_ACTIVE_CASE_DOCUMENT_COUNT:
    return update(state, {
      documentCount: { $set: action.payload.docCount }
    });
  default:
    return state;
  }
};

export default caseDetailReducer;
