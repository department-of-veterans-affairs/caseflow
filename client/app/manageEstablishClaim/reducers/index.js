import * as Constants from '../constants';
import update from 'immutability-helper';

const parseUserQuotasFromApi = (userQuotasFromApi) => {
  return userQuotasFromApi.map((userQuota, index) => ({
    userName: `${index + 1}. ${userQuota.user_name || 'Not Logged In'}`,
    taskCount: parseInt(userQuota.task_count),
    tasksCompletedCount: parseInt(userQuota.tasks_completed_count),
    tasksLeftCount: parseInt(userQuota.tasks_left_count),
    isAssigned: Boolean(userQuota.user_name)
  }));
};

export const getManageEstablishClaimInitialState = (props = {}) => ({
  alert: null,
  employeeCount: props.employeeCount,
  userQuotas: parseUserQuotasFromApi(props.userQuotas || [])
});

export const manageEstablishClaim = function(state = getManageEstablishClaimInitialState(), action) {
  switch (action.type) {
  case Constants.CHANGE_EMPLOYEE_COUNT:
    return update(state, { employeeCount: { $set: action.payload.employeeCount } });
  case Constants.SET_ALERT:
    return update(state, { alert: { $set: action.payload.alert } });
  case Constants.CLEAR_ALERT:
    return update(state, { alert: { $set: null } });
  case Constants.SET_USER_QUOTAS_FROM_API:
    return update(state, {
      userQuotas: { $set: parseUserQuotasFromApi(action.payload.userQuotas) },
      employeeCount: { $set: action.payload.userQuotas.length }
    });
  default:
    return state;
  }
};

export default manageEstablishClaim;
