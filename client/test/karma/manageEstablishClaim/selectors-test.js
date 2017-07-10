import { getQuotaTotals } from '../../../app/manageEstablishClaim/selectors';
import { expect } from 'chai';

describe('manageEstablishClaim selectors', () => {
  context('.getQuotaTotals', () => {
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

      expect(result.taskCount).to.equal(7);
      expect(result.tasksCompletedCount).to.equal(5);
      expect(result.tasksLeftCount).to.equal(2);
    });

    it('returns total values when no quotas', () => {
      let userQuotas = [];
      let result = getQuotaTotals({ userQuotas });

      expect(result.taskCount).to.equal(0);
      expect(result.tasksCompletedCount).to.equal(0);
      expect(result.tasksLeftCount).to.equal(0);
    });
  });
});
