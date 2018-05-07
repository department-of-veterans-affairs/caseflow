import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  activeCase: null,
  activeTask: null
};

export const caseDetailReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_ACTIVE_CASE_AND_TASK:
    return initialState;
  case Constants.SET_ACTIVE_CASE:
    return update(state, {
      activeCase: { $set: action.payload.caseObj }
    });
  case Constants.SET_ACTIVE_TASK:
    return update(state, {
      activeTask: { $set: action.payload.taskObj }
    });
  default:
    return state;
  }
};

export default caseDetailReducer;
