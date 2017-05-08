import * as Constants from '../constants';
import update from 'immutability-helper';

const parseUserQuotasFromApi = (userQuotasFromApi) => {
  return userQuotasFromApi.map((userQuota, index) => ({
    userName: `${index + 1}. ${userQuota.user_name || 'Not logged in'}`,
    taskCount: userQuota.task_count,
    tasksCompletedCount: userQuota.tasks_completed_count,
    tasksLeftCount: userQuota.tasks_left_count,
    isAssigned: Boolean(userQuota.user_name)
  }));
};

export const getManageEstablishClaimInitialState = (props = { userQuotas: [] }) => ({
  alert: null,
  employeeCount: props.userQuotas.length,
  userQuotas: parseUserQuotasFromApi(props.userQuotas)
});

export const manageEstablishClaim = function(state = getManageEstablishClaimInitialState(), action) {
  switch (action.type) {
  case Constants.CHANGE_EMPLOYEE_COUNT:
    return update(state, { employeeCount: { $set: action.payload.employeeCount } });
  case Constants.SET_ALERT:
    return update(state, { alert: { $set: action.payload.alert } });
  case Constants.CLEAR_ALERT:
    return update(state, { alert: { $set: null } });
  case Constants.REQUEST_USER_QUOTAS_SUCCESS:
    return update(state, {
      userQuotas: { $set: parseUserQuotasFromApi(action.payload.userQuotas) },
      employeeCount: { $set: action.payload.userQuotas.length }
    });
  default:
    return state;
  }
};

export default manageEstablishClaim;
