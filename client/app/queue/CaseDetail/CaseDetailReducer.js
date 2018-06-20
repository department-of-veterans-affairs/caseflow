import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';

export const initialState = {
  activeAppeal: null,
  activeTask: null
};

export const caseDetailReducer = (state = initialState, action = {}) => {
  switch (action.type) {
  case Constants.CLEAR_ACTIVE_APPEAL_AND_TASK:
    return initialState;
  case Constants.SET_ACTIVE_APPEAL:
    return update(state, {
      activeAppeal: { $set: action.payload.appeal }
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
