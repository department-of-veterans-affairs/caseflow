import * as Constants from '../constants';
import update from 'immutability-helper';

export const getManageEstablishClaimInitialState = (props = {}) => ({
  alert: null,
  employeeCount: props.employeeCount
});

export const manageEstablishClaim = function(state = getManageEstablishClaimInitialState(), action) {
  switch (action.type) {
  case Constants.CHANGE_EMPLOYEE_COUNT:
    return update(state, { employeeCount: { $set: action.payload.employeeCount } });
  case Constants.SET_ALERT:
    return update(state, { alert: { $set: action.payload.alert } });
  case Constants.CLEAR_ALERT:
    return update(state, { alert: { $set: null } });
  default:
    return state;
  }
};

export default manageEstablishClaim;
