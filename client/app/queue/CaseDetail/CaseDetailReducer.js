// @flow
import * as Constants from './actionTypes';
import { update } from '../../util/ReducerUtil';
import type { CaseDetailState } from '../types/state';

export const initialState = {
  activeAppeal: null,
  activeTask: null,
  veteranCaseListIsVisible: false
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
  case Constants.TOGGLE_VETERAN_CASE_LIST:
    return update(state, {
      veteranCaseListIsVisible: { $set: !state.veteranCaseListIsVisible }
    });
  default:
    return state;
  }
};

export default caseDetailReducer;
