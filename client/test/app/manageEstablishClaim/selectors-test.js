import { getQuotaTotals } from '../../../app/manageEstablishClaim/selectors';

describe('manageEstablishClaim selectors', () => {
  describe('.getQuotaTotals', () => {
    it('returns total values', () => {
      let userQuotas = [
        { taskCount: 5,
          tasksCompletedCount: 3,
          tasksCompletedCountByDecisionType: {
            full_grant: 2,
            partial_grant: 1
          },
          tasksLeftCount: 2 },
        { taskCount: 2,
          tasksCompletedCount: 2,
          tasksCompletedCountByDecisionType: {
            full_grant: 1,
            remand: 1
          },
          tasksLeftCount: 0 }
      ];
      let result = getQuotaTotals({ userQuotas });

      expect(result.taskCount).toBe(7);
      expect(result.tasksCompletedCount).toBe(5);
      expect(result.tasksLeftCount).toBe(2);
    });

    it('returns total values when no quotas', () => {
      let userQuotas = [];
      let result = getQuotaTotals({ userQuotas });

      expect(result.taskCount).toBe(0);
      expect(result.tasksCompletedCount).toBe(0);
      expect(result.tasksLeftCount).toBe(0);
    });
  });
});
