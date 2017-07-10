import * as Constants from '../constants';
import update from 'immutability-helper';
import ReducerUtil from '../../util/ReducerUtil';

const parseUserQuotasFromApi = (userQuotasFromApi) => (
  userQuotasFromApi.map((userQuota, index) => ({
    id: userQuota.id,
    index,
    userName: userQuota.user_name || 'Not logged in',
    taskCount: userQuota.task_count,
    isEditingTaskCount: false,
    tasksCompletedCount: userQuota.tasks_completed_count,
    tasksCompletedCountByDecisionType: userQuota.tasks_completed_count_by_decision_type,
    tasksLeftCount: userQuota.tasks_left_count,
    isAssigned: Boolean(userQuota.user_name),
    isLocked: Boolean(userQuota['locked?'])
  }))
);

const updateUserQuotaInState = (state, index, values) => {
  const newUserQuotas = ReducerUtil.changeObjectInArray(state.userQuotas, { index,
    values });


  return update(state, { userQuotas: { $set: newUserQuotas } });
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

  case Constants.BEGIN_EDIT_TASK_COUNT:
    return updateUserQuotaInState(
      state,
      action.payload.userQuotaIndex,
      {
        newTaskCount: state.userQuotas[action.payload.userQuotaIndex].taskCount,
        isEditingTaskCount: true
      }
    );

  case Constants.CHANGE_NEW_TASK_COUNT:
    return updateUserQuotaInState(
      state,
      action.payload.userQuotaIndex,
      { newTaskCount: action.payload.taskCount }
    );

  default:
    return state;
  }
};

export default manageEstablishClaim;
