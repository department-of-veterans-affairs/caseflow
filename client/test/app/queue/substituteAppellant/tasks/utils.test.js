import { uniq } from 'lodash';

import {
  calculateEvidenceSubmissionEndDate,
  filterTasks,
  prepTaskDataForUi,
  shouldAutoSelect,
  shouldDisable,
  shouldHideBasedOnPoaType,
  shouldHide,
  shouldShowBasedOnOtherTasks,
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

      it('should not hide', () => {
        expect(shouldHideBasedOnPoaType(taskInfo, 'other POA type')).toBe(false);
      });
    });
  });

  describe('shouldHide', () => {
    let poaType = 'other poa type';
    const otherOrgTask = { hideFromCaseTimeline: false, assignedTo: { isOrganization: true }, type: 'other task type' };
    const otherUserTask = { hideFromCaseTimeline: false, assignedTo: { isOrganization: false }, type: 'other task type' };

    describe('with hideFromCaseTimeline', () => {
      const userTaskInfo = { hideFromCaseTimeline: true, assignedTo: { isOrganization: false } };
      const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];

      it('returns true', () => {
        expect(shouldHide(userTaskInfo, poaType, allTasks)).toBe(true);
      });
    });

    describe('without hideFromCaseTimeline', () => {
      const userTaskInfo = { hideFromCaseTimeline: false, assignedTo: { isOrganization: false } };
      const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];

      it('returns false', () => {
        expect(shouldHide(userTaskInfo, poaType, allTasks)).toBe(false);
      });
    });

    describe('tasks with a type in the automatedTasks array', () => {
      const userTaskInfo = { taskId: 1, hideFromCaseTimeline: false, type: 'JudgeDecisionReviewTask', assignedTo: { isOrganization: false } };
      const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];
      const poaTypes = ['Attorney', 'Agent', null];

      describe.each(poaTypes)(' poaType: %s', (type) => {
        it('should hide these tasks', () => {
          expect(shouldHide(userTaskInfo, type, allTasks)).toBe(true);
        });
      });

    });

    describe('tasks where hideFromCaseTimeline is false and the type is not in the automatedTasks array', () => {
      describe('the task type is only assigned to a user', () => {
        const userTaskInfo = { hideFromCaseTimeline: false, type: 'RootTask', assignedTo: { isOrganization: false } };

        poaType = 'Attorney';
        const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];

        it('should not hide these tasks', () => {
          expect(shouldHide(userTaskInfo, poaType, allTasks)).toBe(false);
        });
      });
    });

    describe('Bva Dispatch task', () => {
      const userTaskInfo = { taskId: 1, hideFromCaseTimeline: false, type: 'BvaDispatchTask', assignedTo: { isOrganization: false } };
      const orgTaskInfo = { taskId: 2, hideFromCaseTimeline: true, type: 'BvaDispatchTask', assignedTo: { isOrganization: true } };
      const allTasks = [orgTaskInfo, userTaskInfo, otherOrgTask, otherUserTask];

      poaType = 'other poa type';

      it('should hide both organization and user Bva Dispatch tasks', () => {
        expect(shouldHide(userTaskInfo, poaType, allTasks)).toBe(true);
        expect(shouldHide(orgTaskInfo, poaType, allTasks)).toBe(true);
      });

    });
  });

  describe('shouldShowBasedOnOtherTasks', () => {
    describe('org task with hideFromCaseTimeline', () => {
      const orgTask = { taskId: 1, hideFromCaseTimeline: true };

      describe('user task without hideFromCaseTimeline', () => {
        const userTask = { taskId: 2, hideFromCaseTimeline: false };

        it('returns true for org task', () => {
          const tasks = [orgTask, userTask];

          expect(shouldShowBasedOnOtherTasks(orgTask, tasks)).toBe(true);
        });
      });

      describe('user task with hideFromCaseTimeline', () => {
        const userTask = { taskId: 3, hideFromCaseTimeline: true };

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

describe('prepTaskDataForUi', () => {
  describe('with basic evidence submission tasks', () => {
    const tasks = sampleTasksForEvidenceSubmissionDocket();

    it('returns correct result', () => {
      const res = prepTaskDataForUi(tasks);

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
        taskId: 1,
        type: 'InformalHearingPresentationTask',
        closedAt: new Date('2021-05-31'),
        assignedTo: { isOrganization: true },
        hideFromCaseTimeline: true,
      };
      const ihpUserTask = {
        taskId: 2,
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
      substitutionDate: '2021-03-25',
      veteranDateOfDeath: '2021-03-20',
      selectedTasks: tasks
    };
    const result = calculateEvidenceSubmissionEndDate(args);

    expect(result).toBe('2021-06-04');
  });

  it('ensures the evidence submission window is not more than 90 days when date of death precedes the NOD date', () => {
    const args = {
      substitutionDate: '2021-03-25',
      veteranDateOfDeath: '2021-02-01',
      selectedTasks: tasks
    };
    const result = calculateEvidenceSubmissionEndDate(args);

    expect(result).toBe('2021-06-23');
  });
});
