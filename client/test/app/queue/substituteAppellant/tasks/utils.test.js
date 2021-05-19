import { format } from 'date-fns';
import { uniq } from 'lodash';

import {
  calculateEvidenceSubmissionEndDate,
  filterTasks,
  shouldAutoSelect,
  shouldDisable,
  shouldHideBasedOnPoaType,
  shouldHide } from 'app/queue/substituteAppellant/tasks/utils';

import { sampleTasksForEvidenceSubmissionDocket } from 'test/data/queue/substituteAppellant/tasks';

describe('utility functions for task manipulation', () => {
  const nonDistributionTaskTypes = [
    'JudgeAssignTask',
    'JudgeDecisionReviewTask',
    'AttorneyTask',
    'BvaDispatchTask',
    'CavcCorrespondenceMailTask',
    'ClearAndUnmistakeableErrorMailTask',
    'AddressChangeMailTask',
    'CongressionalInterestMailTask',
    'ControlledCorrespondenceMailTask',
    'DeathCertificateMailTask',
    'EvidenceOrArgumentMailTask',
    'ExtensionRequestMailTask',
    'FoiaRequestMailTask',
    'HearingRelatedMailTask',
    'ReconsiderationMotionMailTask',
    'AodMotionMailTask',
    'VacateMotionMailTask',
    'OtherMotionMailTask',
    'PowerOfAttorneyRelatedMailTask',
    'PrivacyActRequestMailTask',
    'PrivacyComplaintMailTask',
    'ReturnedUndeliverableCorrespondenceMailTask',
    'StatusInquiryMailTask',
    'AppealWithdrawalMailTask'
  ];

  describe('shouldAutoSelect', () => {
    it('returns true for DistributionTask', () => {
      const task = { type: 'DistributionTask' };

      expect(shouldAutoSelect(task)).toBe(true);
    });

    it('returns false for others', () => {
      nonDistributionTaskTypes.forEach((taskType) => {
        const nonDt = { type: taskType };

        expect(shouldAutoSelect(nonDt)).toBe(false);
      });
    });
  });

  describe('shouldDisable', () => {
    it('should disable DistributionTask', () => {
      const task = { type: 'DistributionTask' };

      expect(shouldDisable(task)).toBe(true);
    });

    it('returns false for others', () => {
      nonDistributionTaskTypes.forEach((taskType) => {
        const nonDt = { type: taskType };

        expect(shouldDisable(nonDt)).toBe(false);
      });
    });
  });

  describe('shouldHideBasedOnPoaType', () => {
    describe('task type is InformalHearingPresentationTask', () => {
      const taskInfo = { type: 'InformalHearingPresentationTask' };

      it('should hide if the poa is an attorney', () => {
        expect(shouldHideBasedOnPoaType(taskInfo, 'Attorney')).toBe(true);
      });

      it('should hide if the poa is an agent', () => {
        expect(shouldHideBasedOnPoaType(taskInfo, 'Agent')).toBe(true);
      });

      it('should not hide if the poa is not an agent/attorney', () => {
        expect(shouldHideBasedOnPoaType(taskInfo, 'other poa type')).toBe(false);
      });
    });

    describe('task type is not InformalHearingPresentationTask', () => {
      const taskInfo = { type: 'JudgeAssignTask' };

      it('should not hide if the poa is an attorney', () => {
        expect(shouldHideBasedOnPoaType(taskInfo, 'Attorney')).toBe(false);
      });
    });
  });

  describe('shouldHide', () => {
    describe('tasks with a type in the automatedTasks array', () => {
      const taskInfo = { hideFromCaseTimeline: false, type: 'JudgeDecisionReviewTask' };

      it('should hide these tasks', () => {
        expect(shouldHide(taskInfo, 'Attorney')).toBe(true);
      });
    });
    describe('tasks where hideFromCaseTimeline is true', () => {
      const taskInfo = { hideFromCaseTimeline: true, type: 'RootTask' };

      it('should hide these tasks', () => {
        expect(shouldHide(taskInfo, 'Attorney')).toBe(true);
      });
    });
    describe('tasks where hideFromCaseTimeline is false and the type is not in the automatedTasks array', () => {
      const taskInfo = { hideFromCaseTimeline: false, type: 'RootTask' };

      it('should not hide these tasks', () => {
        expect(shouldHide(taskInfo, 'Attorney')).toBe(false);
      });
    });
  });

  describe('filterTasks', () => {
    const tasks = sampleTasksForEvidenceSubmissionDocket();

    it('filters tasks', () => {
      const filtered = filterTasks(tasks);
      const uniqueTypes = uniq(filtered, 'type');

      expect(filtered.length).toBeLessThan(tasks.length);
      expect(uniqueTypes.length).toBe(filtered.length);

      expect(filtered).toMatchSnapshot();
    });

    it('returns only org tasks', () => {
      const filtered = filterTasks(tasks);
      const bvaDispatchTask = filtered.find((task) => task.type === 'BvaDispatchTask');

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
});

describe('calculateEvidenceSubmissionEndDate', () => {
  const tasks = sampleTasksForEvidenceSubmissionDocket();

  it('outputs the expected result', () => {
    const args = {
      substitutionDate: new Date('2021-03-25'),
      veteranDateOfDeath: new Date('2021-03-20'),
      selectedTasks: tasks
    };
    const result = calculateEvidenceSubmissionEndDate(args);

    expect(format(result, 'yyyy-MM-dd')).toBe('2021-06-04');
  });
});
