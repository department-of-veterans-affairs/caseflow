import { uniq } from 'lodash';
import {
  filterDuplicateTasks,
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

  describe('filterDuplicateTasks', () => {
    const tasks = sampleEvidenceSubmissionTasks();

    it('filters out duplicates', () => {
      const filtered = filterDuplicateTasks(tasks);
      const uniqueTypes = uniq(filtered, 'type');

      expect(filtered.length).toBeLessThan(tasks.length);
      expect(uniqueTypes.length).toBe(filtered.length);

      expect(filtered).toMatchSnapshot();
    });

    it('prefers user tasks', () => {
      const filtered = filterDuplicateTasks(tasks);
      const bvaDispatchTask = filtered.find(
        (task) => task.type === 'BvaDispatchTask'
      );

      expect(bvaDispatchTask?.assignedTo?.isOrganization).toBe(false);
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
