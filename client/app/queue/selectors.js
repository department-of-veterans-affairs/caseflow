import { createSelector } from 'reselect';
import { filter, find, keyBy, map, merge, orderBy, reduce } from 'lodash';
import { taskIsActive, taskIsOnHold } from './utils';

import TASK_STATUSES from '../../constants/TASK_STATUSES';

import COPY from '../../COPY';

export const selectedTasksSelector = (state, userId) => {
  return map(state.queue.isTaskAssignedToUserSelected[userId] || {}, (selected, id) => {
    if (!selected) {
      return;
    }

    return state.queue.tasks[id] || state.queue.amaTasks[id];
  }).filter(Boolean);
};

const getTasks = (state) => state.queue.tasks;
const getAmaTasks = (state) => state.queue.amaTasks;
const getAppeals = (state) => state.queue.appeals;
const getAppealDetails = (state) => state.queue.appealDetails;
const getUserCssId = (state) => state.ui.targetUser?.cssId || state.ui.userCssId;
const getActiveOrgId = (state) => state.ui.activeOrganization.id;
const getAppealId = (state, props) => props.appealId;
const getTaskUniqueId = (state, props) => props.taskId;
const getCaseflowVeteranId = (state, props) => props.caseflowVeteranId;
const getClaimReviews = (state) => state.queue.claimReviews;

const incompleteTasksSelector = (tasks) => filter(tasks, (task) => taskIsActive(task));
const completeTasksSelector = (tasks) => filter(tasks, (task) => !taskIsActive(task));
const taskIsNotOnHoldSelector = (tasks) => filter(tasks, (task) => !taskIsOnHold(task));
const workTasksSelector = (tasks) => filter(tasks, (task) => !task.hideFromQueueTableView);

const tasksWithAppealSelector = createSelector(
  [getTasks, getAmaTasks, getAppeals, getAppealDetails],
  (tasks, amaTasks, appeals, appealDetails) => {
    return [
      ...map(tasks, (task) => ({
        ...task,
        appeal: {
          ...find(appeals, (appeal) => task.externalAppealId === appeal.externalId),
          ...find(appealDetails, (appealDetail) => task.externalAppealId === appealDetail.externalId)
        }
      })),
      ...map(amaTasks, (amaTask) => ({
        ...amaTask,
        appeal: {
          ...find(appeals, (appeal) => amaTask.externalAppealId === appeal.externalId),
          ...find(appealDetails, (appealDetail) => amaTask.externalAppealId === appealDetail.externalId)
        }
      }))
    ];
  }
);

export const taskById = createSelector(
  [tasksWithAppealSelector, getTaskUniqueId],
  (tasks, taskId) => find(tasks, (task) => task.uniqueId === taskId)
);

const appealsWithDetailsSelector = createSelector(
  [getAppeals, getAppealDetails],
  (appeals, appealDetails) => ({ ...merge(appeals, appealDetails) })
);

const claimReviewsSelector = createSelector(
  [getClaimReviews],
  (claimReviews) => claimReviews
);

export const appealWithDetailSelector = createSelector(
  [appealsWithDetailsSelector, getAppealId],
  (appeals, appealId) => appeals[appealId]
);

export const getAllTasksForAppeal = createSelector(
  [getTasks, getAmaTasks, getAppealId],
  (tasks, amaTasks, appealId) => {
    return filter(tasks, (task) => task.externalAppealId === appealId).concat(
      filter(amaTasks, (task) => task.externalAppealId === appealId)
    );
  }
);

export const appealsByCaseflowVeteranId = createSelector(
  [appealsWithDetailsSelector, getCaseflowVeteranId],
  (appeals, caseflowVeteranId) =>
    filter(
      appeals,
      (appeal) =>
        appeal.caseflowVeteranId &&
        caseflowVeteranId &&
        appeal.caseflowVeteranId.toString() === caseflowVeteranId.toString()
    )
);

export const claimReviewsByCaseflowVeteranId = createSelector(
  [claimReviewsSelector, getCaseflowVeteranId],
  (claimReviews, caseflowVeteranId) =>
    filter(
      claimReviews,
      (claimReview) =>
        claimReview.caseflowVeteranId &&
        caseflowVeteranId &&
        claimReview.caseflowVeteranId.toString() === caseflowVeteranId.toString()
    )
);

const tasksByAssigneeCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks, cssId) => filter(tasks, (task) => task.assignedTo.cssId === cssId)
);

const tasksByAssigneeOrgSelector = createSelector(
  [tasksWithAppealSelector, getActiveOrgId],
  (tasks, orgId) => filter(tasks, (task) => task.assignedTo.id === orgId)
);

export const legacyJudgeTasksAssignedToUser = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) => filter(tasks, (task) => task.type === 'JudgeLegacyDecisionReviewTask' || task.type === 'JudgeLegacyAssignTask')
);

const workTasksByAssigneeCssIdSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) => workTasksSelector(tasks)
);

const workTasksByAssigneeOrgSelector = createSelector(
  [tasksByAssigneeOrgSelector],
  (tasks) => workTasksSelector(tasks)
);

const tasksByAssignerCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks, cssId) => filter(tasks, (task) => task.assignedBy.cssId === cssId)
);

export const legacyAttorneyTasksAssignedByUser = createSelector(
  [tasksByAssignerCssIdSelector],
  (tasks) => filter(tasks, (task) => task.type === 'AttorneyLegacyTask')
);

const actionableTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => filter(tasks, (task) => task.availableActions.length)
);

export const scheduleHearingTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => filter(incompleteTasksSelector(tasks), (task) => task.type === 'ScheduleHearingTask')
);

export const openScheduleHearingTasksForAppeal = createSelector(
  [actionableTasksForAppeal],
  (tasks) => filter(incompleteTasksSelector(tasks), (task) => task.type === 'ScheduleHearingTask')
);

export const allHearingTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => filter(tasks, (task) => task.type === 'HearingTask')
);

export const rootTasksForAppeal = createSelector(
  [actionableTasksForAppeal],
  (tasks) => filter(tasks, (task) => task.type === 'RootTask')
);

export const distributionTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => filter(tasks, (task) => task.type === 'DistributionTask')
);

export const caseTimelineTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => orderBy(filter(completeTasksSelector(tasks), (task) => !task.hideFromCaseTimeline), ['completedAt'], ['desc'])
);

export const taskSnapshotTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => orderBy(filter(incompleteTasksSelector(tasks), (task) => !task.hideFromTaskSnapshot), ['createdAt'], ['desc'])
);

const taskIsLegacyAttorneyJudgeTask = (task) => {
  const legacyAttorneyJudgeTaskTypes = [
    'AttorneyLegacyTask',
    'JudgeLegacyTask',
    'JudgeLegacyAssignTask',
    'JudgeLegacyDecisionReviewTask'
  ];

  return legacyAttorneyJudgeTaskTypes.includes(task.type);
};

export const attorneyLegacyAssignedTasksSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) => tasks.filter((task) => taskIsLegacyAttorneyJudgeTask(task))
);

export const judgeLegacyDecisionReviewTasksSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) => filter(tasks, (task) => task.label === COPY.JUDGE_DECISION_REVIEW_TASK_LABEL)
);

export const judgeAssignTasksSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) =>
    filter(tasks, (task) => {
      if (task.appealType === 'Appeal' || !task.isLegacy) {
        return (
          task.label === COPY.JUDGE_ASSIGN_TASK_LABEL &&
          (task.status === TASK_STATUSES.in_progress || task.status === TASK_STATUSES.assigned)
        );
      }

      return task.label === COPY.JUDGE_ASSIGN_TASK_LABEL;
    })
);

export const camoAssignTasksSelector = createSelector(
  [workTasksByAssigneeOrgSelector],
  (tasks) =>
    filter(tasks, (task) => {
      return (
        task.label === COPY.REVIEW_DOCUMENTATION_TASK_LABEL &&
        (task.status === TASK_STATUSES.in_progress || task.status === TASK_STATUSES.assigned)
      );
    })
);

// ***************** Non-memoized selectors *****************

const getAttorney = (state, attorneyId) => {
  if (!state.queue.attorneysOfJudge) {
    return null;
  }

  return find(state.queue.attorneysOfJudge, (attorney) => attorney.id.toString() === attorneyId);
};

export const getAssignedTasks = (state, attorneyId) => {
  const tasks = incompleteTasksSelector(taskIsNotOnHoldSelector(tasksWithAppealSelector(state)));
  const attorney = getAttorney(state, attorneyId);
  const cssId = attorney ? attorney.css_id : null;

  return filter(tasks, (task) => task.assignedTo.cssId === cssId);
};

export const getTasksByUserId = (state) => {
  const tasks = incompleteTasksSelector(taskIsNotOnHoldSelector(tasksWithAppealSelector(state)));
  const attorneys = state.queue.attorneysOfJudge;
  const attorneysByCssId = keyBy(attorneys, 'css_id');

  return reduce(
    tasks,
    (appealsByUserId, task) => {
      const appealCssId = task.assignedTo.cssId;
      const attorney = attorneysByCssId[appealCssId];

      if (!attorney) {
        return appealsByUserId;
      }

      appealsByUserId[attorney.id] = [...(appealsByUserId[attorney.id] || []), task];

      return appealsByUserId;
    },
    {}
  );
};
