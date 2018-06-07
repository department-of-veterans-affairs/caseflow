// @flow
import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';
import type { Task } from '../reducers';

export type CaseDetailState = {|
  activeAppeal: ?Object,
  activeTask: ?Task
|};

export const initialState = {
  activeAppeal: null,
  activeTask: null
};

export const caseDetailReducer = (state: CaseDetailState = initialState, action: {[string]: Object} = {}) => {
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
