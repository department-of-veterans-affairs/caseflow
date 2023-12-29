import { ACTIONS } from './constants';
import { combineReducers } from 'redux';
import { timeFunction } from '../util/PerfDebug';

import caseflowDistributionAdminReducer from './admin/caseflowDistributionAdminReducer/caseflowDistributionAdminReducer';

export const initialState = {};

const createReducer = (handlers) => {
  return (state = initialState, action) => {
    return Object.prototype.hasOwnProperty.call(handlers, action.type) ? handlers[action.type](state, action) : state;
  };
};

const rootReducer = combineReducers({
  caseflowDistributionAdmin: caseflowDistributionAdminReducer
});

export default timeFunction(
  rootReducer,
  (timeLabel, state, action) => `Action ${action.type} reducer time: ${timeLabel}`
);
