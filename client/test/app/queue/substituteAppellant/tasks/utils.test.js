import { uniq } from 'lodash';

import {
  automatedTasks,
  nonAutomatedTasksToHide,
  calculateEvidenceSubmissionEndDate,
  filterTasks,
  prepTaskDataForUi,
  shouldAutoSelect,
  shouldDisable,
  shouldHideBasedOnPoa,
  shouldHide,
  shouldShowBasedOnOtherTasks, shouldDisableBasedOnTaskType, disabledTasksBasedOnSelections,
  hearingAdminActions, mailTasks } from 'app/queue/substituteAppellant/tasks/utils';

import { sampleTasksForEvidenceSubmissionDocket } from 'test/data/queue/substituteAppellant/tasks';
import { isSameDay } from 'date-fns';
import parseISO from 'date-fns/parseISO';

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

  describe('shouldDisableBasedOnTaskType', () => {
    describe('when a ScheduleVeteranTask is selected', () => {
      const selectedTaskTypes = ['ExampleTask', 'ScheduleHearingTask'];

      const shouldDisables = [
        'EvidenceSubmissionWindowTask',
        'TranscriptionTask'
      ];

      const shouldNotDisables = [
        'ScheduleHearingTask',
        'ExampleTask'
      ];

      it.each(shouldDisables)('should disable task type %s', (taskType) => {
        expect(shouldDisableBasedOnTaskType(taskType, selectedTaskTypes)).toBe(true);
      });

      it.each(shouldNotDisables)('should not disable task type %s', (taskType) => {
        expect(shouldDisableBasedOnTaskType(taskType, selectedTaskTypes)).toBe(false);
      });
    });
  });

  describe('disabledTasksBasedOnSelections', () => {
    const tasks = [
      { taskId: 1, type: 'EvidenceSubmissionWindowTask' },
      { taskId: 2, type: 'ScheduleHearingTask' },
      { taskId: 3, type: 'TranscriptionTask' }
    ];

    describe('when EvidenceSubmissionWindowTask is selected', () => {
      const selectedTaskIds = [1];

      it('disables the appropriate types', () => {
        expect(disabledTasksBasedOnSelections({ tasks, selectedTaskIds })).toEqual(
          expect.arrayContaining([
            expect.objectContaining({ type: 'EvidenceSubmissionWindowTask', disabled: false }),
            expect.objectContaining({ type: 'ScheduleHearingTask', disabled: true }),
            expect.objectContaining({ type: 'TranscriptionTask', disabled: false })
          ])
        );
      });
    });
  });

  const poa = { ihp_allowed: true };

  describe('shouldHideBasedOnPoa', () => {

    describe('task type is InformalHearingPresentationTask', () => {
      const taskInfo = { type: 'InformalHearingPresentationTask' };

      it('should hide if the backend says rep is non-ihp-writing', () => {
        expect(shouldHideBasedOnPoa(taskInfo, { ihp_allowed: false })).toBe(true);
      });
    });

    describe('task type is not InformalHearingPresentationTask', () => {
      const taskInfo = { type: 'JudgeAssignTask' };

      it('should not hide', () => {
        expect(shouldHideBasedOnPoa(taskInfo, { ihp_allowed: false })).toBe(false);
      });
    });
  });

  describe('shouldHide', () => {

    const otherOrgTask = { hideFromCaseTimeline: false, assignedTo: { isOrganization: true }, type: 'other task type' };
    const otherUserTask = { hideFromCaseTimeline: false, assignedTo: { isOrganization: false }, type: 'other task type' };

    describe('with hideFromCaseTimeline', () => {
      const userTaskInfo = { hideFromCaseTimeline: true, assignedTo: { isOrganization: false } };
      const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];

      it('returns true', () => {
        expect(shouldHide(userTaskInfo, poa, allTasks)).toBe(true);
      });
    });

    describe('without hideFromCaseTimeline', () => {
      const userTaskInfo = { hideFromCaseTimeline: false, assignedTo: { isOrganization: false } };
      const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];

      it('returns false', () => {
        expect(shouldHide(userTaskInfo, poa, allTasks)).toBe(false);
      });
    });

    describe('tasks in automatedTasks array', () => {
      it.each(automatedTasks)('should hide %s', (type) => {
        const task = { id: 1, type, assignedTo: { isOrganization: false } };

        expect(shouldHide(task, null, [])).toBe(true);
      });
    });

    describe('tasks in nonAutomatedTasksToHide array', () => {
      it.each(nonAutomatedTasksToHide)('should hide %s', (type) => {
        const task = { id: 1, type, assignedTo: { isOrganization: false } };

        expect(shouldHide(task, null, [])).toBe(true);
      });
    });

    describe('tasks in mailTasks array', () => {
      it.each(mailTasks)('should hide %s', (type) => {
        const task = { id: 1, type, assignedTo: { isOrganization: false } };

        expect(shouldHide(task, null, [])).toBe(true);
      });
    });

    describe('tasks in hearingAdminActions array', () => {
      it.each(hearingAdminActions)('should hide %s', (type) => {
        const task = { id: 1, type, assignedTo: { isOrganization: false } };

        expect(shouldHide(task, null, [])).toBe(true);
      });
    });

    describe('tasks with a type in the automatedTasks array by poaType', () => {
      const userTaskInfo = {
        taskId: 1,
        hideFromCaseTimeline: false,
        type: 'JudgeDecisionReviewTask',
        assignedTo: { isOrganization: false },
      };
      const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];

      it('should hide these tasks', () => {
        expect(shouldHide(userTaskInfo, poa, allTasks)).toBe(true);
      });

    });

    describe('tasks where hideFromCaseTimeline is false and the type is not in the automatedTasks array', () => {
      describe('the task type is only assigned to a user', () => {
        const userTaskInfo = { hideFromCaseTimeline: false, type: 'RootTask', assignedTo: { isOrganization: false } };

        const allTasks = [userTaskInfo, otherOrgTask, otherUserTask];

        it('should not hide these tasks', () => {
          expect(shouldHide(userTaskInfo, poa, allTasks)).toBe(false);
        });
      });
    });

    describe('Bva Dispatch task', () => {
      const userTaskInfo = { taskId: 1, hideFromCaseTimeline: false, type: 'BvaDispatchTask', assignedTo: { isOrganization: false } };
      const orgTaskInfo = { taskId: 2, hideFromCaseTimeline: true, type: 'BvaDispatchTask', assignedTo: { isOrganization: true } };
      const allTasks = [orgTaskInfo, userTaskInfo, otherOrgTask, otherUserTask];

      it('should hide both organization and user Bva Dispatch tasks', () => {
        expect(shouldHide(userTaskInfo, poa, allTasks)).toBe(true);
        expect(shouldHide(orgTaskInfo, poa, allTasks)).toBe(true);
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

    expect(isSameDay(parseISO(result), parseISO('2021-06-04'))).toBe(true);
  });

  it('ensures the evidence submission window is not more than 90 days when date of death precedes the NOD date', () => {
    const args = {
      substitutionDate: '2021-03-25',
      veteranDateOfDeath: '2021-02-01',
      selectedTasks: tasks
    };
    const result = calculateEvidenceSubmissionEndDate(args);

    expect(isSameDay(parseISO(result), parseISO('2021-06-23'))).toBe(true);
  });
});
