import { createSelector } from 'reselect';

const getUserQuotas = (state) => state.userQuotas;

export const getQuotaTotals = createSelector([getUserQuotas], (userQuotas) => {
  return userQuotas.reduce((totals, userQuota) => ({
    taskCount: totals.taskCount + userQuota.taskCount,
    tasksCompletedCount: totals.tasksCompletedCount + userQuota.tasksCompletedCount,
    tasksLeftCount: totals.tasksLeftCount + userQuota.tasksLeftCount,
    fullGrantCount: totals.fullGrantCount + (
      userQuota.tasksCompletedCountByDecisionType.full_grant || 0
    ),
    partialGrantCount: totals.partialGrantCount + (
      userQuota.tasksCompletedCountByDecisionType.partial_grant || 0
    ),
    remandCount: totals.remandCount + (
      userQuota.tasksCompletedCountByDecisionType.remand || 0
    )
  }), { taskCount: 0,
    tasksCompletedCount: 0,
    tasksLeftCount: 0,
    fullGrantCount: 0,
    partialGrantCount: 0,
    remandCount: 0
  });
});
