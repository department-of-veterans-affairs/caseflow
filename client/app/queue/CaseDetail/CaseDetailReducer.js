import * as Constants from './actionTypes';
import { SEARCH_ERROR_FOR } from '../constants';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  activeCase: null
};

export const caseDetailReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_ACTIVE_CASE:
    return initialState;
  case Constants.SET_ACTIVE_CASE:
    return update(state, {
      activeCase: { $set: action.payload.caseObj }
    });
  default:
    return state;
  }
};

export default caseDetailReducer;
