import { createSelector } from 'reselect';

const getUserQuotas = (state) => state.userQuotas;

export const getQuotaTotals = createSelector([getUserQuotas], (userQuotas) => {
  return userQuotas.reduce((totals, userQuota) => ({
    taskCount: totals.taskCount + userQuota.taskCount,
    tasksCompletedCount: totals.tasksCompletedCount + userQuota.tasksCompletedCount,
    tasksLeftCount: totals.tasksLeftCount + userQuota.tasksLeftCount
  }), { taskCount: 0,
    tasksCompletedCount: 0,
    tasksLeftCount: 0 });
});
