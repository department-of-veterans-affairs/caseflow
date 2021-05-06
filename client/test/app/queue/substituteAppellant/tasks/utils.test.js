import { stubTrue, uniq } from 'lodash';
import {
  filterTasks,
  formatTaskData,
  shouldAutoSelect,
  shouldDisable,
} from 'app/queue/substituteAppellant/tasks/utils';
import { sampleEvidenceSubmissionTasks } from 'test/data/queue/substituteAppellant/tasks';

describe('utility functions for task manipulation', () => {
  describe('shouldAutoSelect', () => {
    it('returns true for DistributionTask', () => {
      const task = { type: 'DistributionTask' };

      expect(shouldAutoSelect(task)).toBe(true);
    });

    it('returns false for others', () => {
      const task = { type: 'SomeOtherTask' };

      expect(shouldAutoSelect(task)).toBe(false);
    });
  });

  describe('shouldDisable', () => {
    it('should disable DistributionTask', () => {
      const task = { type: 'DistributionTask' };

      expect(shouldDisable(task)).toBe(true);
    });

    it('returns false for others', () => {
      const task = { type: 'SomeOtherTask' };

      expect(shouldDisable(task)).toBe(false);
    });
  });

  describe('filterTasks', () => {
    const tasks = sampleEvidenceSubmissionTasks();

    it('filters tasks', () => {
      const filtered = filterTasks(tasks);
      const uniqueTypes = uniq(filtered, 'type');

      expect(filtered.length).toBeLessThan(tasks.length);
      expect(uniqueTypes.length).toBe(filtered.length);

      expect(filtered).toMatchSnapshot();
    });

    // add logic to test for tasks only being cancelled or closed

    // pass in an array where task.closedAt is null and make sure it doesn't get returned back

    it('prefers org tasks', () => {
      const filtered = filterTasks(tasks);
      const bvaDispatchTask = filtered.find(
        (task) => task.type === 'BvaDispatchTask'
      );

      expect(bvaDispatchTask?.assignedTo?.isOrganization).toBe(true);
    });

    it('only allows for completed or cancelled tasks', () => {
      // needs to be an organization or would be filtered
      const assignedTo = { isOrganization: true };
      const filtered = filterTasks([{ closedAt: '2021-04-01', assignedTo }, { closedAt: null, assignedTo }]);

      expect(filtered.length).toBe(1);
      expect(filtered[0].closedAt).toBeTruthy();
      expect(filtered).toMatchSnapshot();
    });
  });

  describe('formatTaskData', () => {
    describe('Evidence Submission sample', () => {
      const tasks = sampleEvidenceSubmissionTasks();

      it('returns correct result', () => {
        const result = formatTaskData(tasks);

        expect(result).toMatchSnapshot();
      });
    });
  });
});
