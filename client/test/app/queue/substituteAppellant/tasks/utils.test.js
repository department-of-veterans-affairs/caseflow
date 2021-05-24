import { format } from 'date-fns';
import { uniq } from 'lodash';

import {
  calculateEvidenceSubmissionEndDate,
  filterTasks,
  prepTaskDataForUi,
  shouldAutoSelect,
  shouldDisable,
  shouldHide,
  shouldShowBasedOnOtherTasks
} from 'app/queue/substituteAppellant/tasks/utils';

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
    'AppealWithdrawalMailTask',
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

  describe('shouldHide', () => {
    describe('with hideFromCaseTimeline', () => {
      const task = { hideFromCaseTimeline: true };

      it('returns true', () => {
        expect(shouldHide(task)).toBe(true);
      });
    });

    describe('without hideFromCaseTimeline', () => {
      const task = { hideFromCaseTimeline: false };

      it('returns false', () => {
        expect(shouldHide(task)).toBe(false);
      });
    });
  });

  describe('shouldShowBasedOnOtherTasks', () => {
    describe('org task with hideFromCaseTimeline', () => {
      const orgTask = { hideFromCaseTimeline: true };

      describe('user task without hideFromCaseTimeline', () => {
        const userTask = { hideFromCaseTimeline: false };

        it('returns true for org task', () => {
          const tasks = [orgTask, userTask];

          expect(shouldShowBasedOnOtherTasks(orgTask, tasks)).toBe(true);
        });
      });

      describe('user task with hideFromCaseTimeline', () => {
        const userTask = { hideFromCaseTimeline: true };

        it('returns false for org task', () => {
          const tasks = [orgTask, userTask];

          expect(shouldShowBasedOnOtherTasks(orgTask, tasks)).toBe(false);
        });
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
      const bvaDispatchTask = filtered.find(
        (task) => task.type === 'BvaDispatchTask'
      );

      expect(bvaDispatchTask?.assignedTo?.isOrganization).toBe(true);
    });

    it('only allows for completed or cancelled tasks', () => {
      // needs to be an organization or would be filtered
      const assignedTo = { isOrganization: true };
      const filtered = filterTasks([
        { closedAt: '2021-04-01', assignedTo },
        { closedAt: null, assignedTo },
      ]);

      expect(filtered.length).toBe(1);
      expect(filtered[0].closedAt).toBeTruthy();
      expect(filtered).toMatchSnapshot();
    });
  });
});

describe('prepTaskDataForUi', () => {
  describe('with basic evidence submission tasks', () => {
    const tasks = sampleTasksForEvidenceSubmissionDocket();

    it('returns correct result', () => {
      const res = prepTaskDataForUi(tasks);

      expect(res).toMatchSnapshot();

      const distributionTask = res.find(
        (item) => item.type === 'DistributionTask'
      );

      expect(distributionTask).toEqual(
        expect.objectContaining({
          hidden: false,
          selected: true,
          disabled: true,
        })
      );
    });

    describe('with an org task that should be shown', () => {
      const ihpOrgTask = {
        type: 'InformalHearingPresentationTask',
        closedAt: new Date('2021-05-31'),
        assignedTo: { isOrganization: true },
        hideFromCaseTimeline: true,
      };
      const ihpUserTask = {
        type: 'InformalHearingPresentationTask',
        closedAt: new Date('2021-05-31'),
        assignedTo: { isOrganization: false },
        hideFromCaseTimeline: false,
      };
      const ihpTasks = [ihpOrgTask, ihpUserTask];

      const res = prepTaskDataForUi(ihpTasks);

      const ihpTask = res.find(
        (item) => item.type === 'InformalHearingPresentationTask'
      );

      it('returns org task but does not hide', () => {
        expect(ihpTask).toEqual(
          expect.objectContaining({
            assignedTo: expect.objectContaining({
              isOrganization: true,
            }),
            hideFromCaseTimeline: true,
            hidden: false,
          })
        );
      });
    });
  });
});

describe('calculateEvidenceSubmissionEndDate', () => {
  const tasks = sampleTasksForEvidenceSubmissionDocket();

  it('outputs the expected result', () => {
    const args = {
      substitutionDate: new Date('2021-03-25'),
      veteranDateOfDeath: new Date('2021-03-20'),
      selectedTasks: tasks,
    };
    const result = calculateEvidenceSubmissionEndDate(args);

    expect(format(result, 'yyyy-MM-dd')).toBe('2021-06-04');
  });
});
