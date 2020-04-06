import { createSelector } from 'reselect';
import _ from 'lodash';
import {
  taskIsActive,
  taskIsOnHold
} from './utils';

import TASK_STATUSES from '../../constants/TASK_STATUSES';

import COPY from '../../COPY';

export const selectedTasksSelector = (state, userId) => {
  return _.map(
    state.queue.isTaskAssignedToUserSelected[userId] || {},
    (selected, id) => {
      if (!selected) {
        return;
      }

      return state.queue.tasks[id] || state.queue.amaTasks[id];
    }
  ).filter(Boolean);
};

const getTasks = (state) => state.queue.tasks;
const getAmaTasks = (state) => state.queue.amaTasks;
const getAppeals = (state) => state.queue.appeals;
const getAppealDetails = (state) => state.queue.appealDetails;
const getUserCssId = (state) => state.ui.targetUser?.cssId || state.ui.userCssId;
const getAppealId = (state, props) => props.appealId;
const getTaskUniqueId = (state, props) => props.taskId;
const getCaseflowVeteranId = (state, props) => props.caseflowVeteranId;
const getModals = (state) => state.ui.modals;
const getNewDocsForAppeal = (state) => state.queue.newDocsForAppeal;
const getClaimReviews = (state) => state.queue.claimReviews;

export const incompleteTasksSelector = (tasks) => _.filter(tasks, (task) => taskIsActive(task));

export const completeTasksSelector = (tasks) => _.filter(tasks, (task) => !taskIsActive(task));

export const taskIsNotOnHoldSelector = (tasks) =>
  _.filter(tasks, (task) => !taskIsOnHold(task));

export const workTasksSelector = (tasks) =>
  _.filter(tasks, (task) => !task.hideFromQueueTableView);

export const trackingTasksSelector = (tasks) =>
  _.filter(tasks, (task) => task.type === 'TrackVeteranTask');

export const getActiveModalType = createSelector(
  [getModals],
  (modals) => _.find(Object.keys(modals), (modalName) => modals[modalName])
);

export const tasksWithAppealSelector = createSelector(
  [getTasks, getAmaTasks, getAppeals, getAppealDetails],
  (tasks, amaTasks, appeals, appealDetails) => {
    return [
      ..._.map(tasks, (task) => ({
        ...task,
        appeal: {
          ..._.find(appeals, (appeal) => task.externalAppealId === appeal.externalId),
          ..._.find(appealDetails, (appealDetail) => task.externalAppealId === appealDetail.externalId)
        }
      })),
      ..._.map(amaTasks, (amaTask) => ({
        ...amaTask,
        appeal: {
          ..._.find(appeals, (appeal) => amaTask.externalAppealId === appeal.externalId),
          ..._.find(appealDetails, (appealDetail) => amaTask.externalAppealId === appealDetail.externalId)
        }
      }))
    ];
  }
);

// To differentiate between tracking tasks which exist purely to provide visibility into appeals.
export const workTasksWithAppealSelector = createSelector(
  [tasksWithAppealSelector], (tasks) => workTasksSelector(tasks)
);

export const taskById = createSelector(
  [tasksWithAppealSelector, getTaskUniqueId],
  (tasks, taskId) =>
    _.find(tasks, (task) => task.uniqueId === taskId)
);

export const appealsWithDetailsSelector = createSelector(
  [getAppeals, getAppealDetails],
  (appeals, appealDetails) => {
    return _.merge(appeals, appealDetails);
  }
);

export const claimReviewsSelector = createSelector(
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
    return _.filter(tasks, (task) => task.externalAppealId === appealId).
      concat(_.filter(amaTasks, (task) => task.externalAppealId === appealId));
  }
);

export const incompleteTasksForAppeal = createSelector(
  [getAllTasksForAppeal], (tasks) => incompleteTasksSelector(tasks)
);

export const tasksForAppealAssignedToUserSelector = createSelector(
  [incompleteTasksForAppeal, getUserCssId],
  (tasks, cssId) => {
    return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
  }
);

export const appealsByCaseflowVeteranId = createSelector(
  [appealsWithDetailsSelector, getCaseflowVeteranId],
  (appeals, caseflowVeteranId) =>
    _.filter(appeals, (appeal) => appeal.caseflowVeteranId && caseflowVeteranId &&
      appeal.caseflowVeteranId.toString() === caseflowVeteranId.toString())
);

export const claimReviewsByCaseflowVeteranId = createSelector(
  [claimReviewsSelector, getCaseflowVeteranId],
  (claimReviews, caseflowVeteranId) =>
    _.filter(claimReviews, (claimReview) => claimReview.caseflowVeteranId && caseflowVeteranId &&
      claimReview.caseflowVeteranId.toString() === caseflowVeteranId.toString())
);

export const tasksByAssigneeCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks, cssId) =>
    _.filter(tasks, (task) => task.assignedTo.cssId === cssId)
);

export const workTasksByAssigneeCssIdSelector = createSelector(
  [tasksByAssigneeCssIdSelector], (tasks) => workTasksSelector(tasks)
);

export const tasksByAssignerCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks, cssId) =>
    _.filter(tasks, (task) => task.assignedBy.cssId === cssId)
);

export const incompleteTasksByAssigneeCssIdSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) => incompleteTasksSelector(tasks)
);

export const incompleteTasksByAssignerCssIdSelector = createSelector(
  [tasksByAssignerCssIdSelector],
  (tasks) => incompleteTasksSelector(tasks)
);

export const completeTasksByAssigneeCssIdSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) => completeTasksSelector(tasks)
);

export const actionableTasksForAppeal = createSelector(
  [getAllTasksForAppeal], (tasks) => _.filter(tasks, (task) => task.availableActions.length)
);

export const scheduleHearingTasksForAppeal = createSelector(
  [actionableTasksForAppeal],
  (tasks) => _.filter(incompleteTasksSelector(tasks), (task) => task.type === 'ScheduleHearingTask')
);

export const rootTasksForAppeal = createSelector(
  [actionableTasksForAppeal], (tasks) => _.filter(tasks, (task) => task.type === 'RootTask')
);

export const caseTimelineTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => _.orderBy(_.filter(completeTasksSelector(tasks), (task) =>
    !task.hideFromCaseTimeline), ['completedAt'], ['desc'])
);

export const taskSnapshotTasksForAppeal = createSelector(
  [getAllTasksForAppeal],
  (tasks) => _.orderBy(_.filter(incompleteTasksSelector(tasks), (task) =>
    !task.hideFromTaskSnapshot), ['createdAt'], ['desc'])
);

export const newTasksByAssigneeCssIdSelector = createSelector(
  [incompleteTasksByAssigneeCssIdSelector],
  (tasks) => tasks.filter((task) => !taskIsOnHold(task))
);

const taskIsLegacyAttorneyJudgeTask = (task) => {
  const legacyAttorneyJudgeTaskTypes =
    ['AttorneyLegacyTask', 'JudgeLegacyTask', 'JudgeLegacyAssignTask', 'JudgeLegacyDecisionReviewTask'];

  return legacyAttorneyJudgeTaskTypes.includes(task.type);
};

export const workableTasksByAssigneeCssIdSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) => tasks.filter(
    (task) => {
      return (taskIsLegacyAttorneyJudgeTask(task) ||
          task.status === TASK_STATUSES.assigned ||
          task.status === TASK_STATUSES.in_progress);
    }
  )
);

const incompleteTasksWithHold = createSelector(
  [incompleteTasksByAssigneeCssIdSelector],
  (tasks) => tasks.filter((task) => taskIsOnHold(task))
);

export const onHoldTasksByAssigneeCssIdSelector = createSelector(
  [incompleteTasksWithHold, getNewDocsForAppeal],
  (tasks) => tasks.filter((task) =>
    taskIsOnHold(task)
  )
);

export const onHoldTasksForAttorney = createSelector(
  [incompleteTasksWithHold, incompleteTasksByAssignerCssIdSelector],
  (incompleteWithHold, incompleteByAssigner) => {
    // Include incompleteTasksByAssignerCssIdSelector so that we can display on hold AttorneyLegacyTasks without
    // actually having the AttorneyLegacyTask in the set of incompleteTasksWithHold.
    //
    // Favor this approach instead of filtering on task's appealType (LegacyAppeal) to be resilient to upcoming
    // migration away from DAS in favor of Caseflow tasks for all appeal types.
    const appealsAlreadyRepresented = incompleteWithHold.map((task) => task.appealId);
    const uniqueOnHoldTasksByAssigner = _.filter(
      incompleteByAssigner, (task) => !appealsAlreadyRepresented.includes(task.appealId));

    return incompleteWithHold.concat(uniqueOnHoldTasksByAssigner);
  }
);

export const judgeDecisionReviewTasksSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) => _.filter(tasks, (task) => {
    if (task.appealType === 'Appeal') {
      return ([COPY.JUDGE_DECISION_REVIEW_TASK_LABEL,
        COPY.JUDGE_QUALITY_REVIEW_TASK_LABEL,
        COPY.JUDGE_DISPATCH_RETURN_TASK_LABEL,
        COPY.JUDGE_ADDRESS_MOTION_TO_VACATE_TASK_LABEL].includes(task.label)) &&
        (task.status === TASK_STATUSES.in_progress || task.status === TASK_STATUSES.assigned);
    }

    // eslint-disable-next-line no-undefined
    return [null, undefined, COPY.JUDGE_DECISION_REVIEW_TASK_LABEL,
      COPY.JUDGE_QUALITY_REVIEW_TASK_LABEL,
      COPY.JUDGE_DISPATCH_RETURN_TASK_LABEL,
      COPY.JUDGE_ADDRESS_MOTION_TO_VACATE_TASK_LABEL].includes(task.label);
  })
);

export const judgeAssignTasksSelector = createSelector(
  [workTasksByAssigneeCssIdSelector],
  (tasks) => _.filter(tasks, (task) => {
    if (task.appealType === 'Appeal' || !task.isLegacy) {
      return task.label === COPY.JUDGE_ASSIGN_TASK_LABEL &&
        (task.status === TASK_STATUSES.in_progress || task.status === TASK_STATUSES.assigned);
    }

    return task.label === COPY.JUDGE_ASSIGN_TASK_LABEL;
  })
);

// ***************** Non-memoized selectors *****************

const getAttorney = (state, attorneyId) => {
  if (!state.queue.attorneysOfJudge) {
    return null;
  }

  return _.find(state.queue.attorneysOfJudge, (attorney) => attorney.id.toString() === attorneyId);
};

export const getAssignedTasks = (state, attorneyId) => {
  const tasks =
    incompleteTasksSelector(
      taskIsNotOnHoldSelector(
        tasksWithAppealSelector(state)));
  const attorney = getAttorney(state, attorneyId);
  const cssId = attorney ? attorney.css_id : null;

  return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
};

export const getTasksByUserId = (state) => {
  const tasks =
    incompleteTasksSelector(
      taskIsNotOnHoldSelector(
        tasksWithAppealSelector(state)));
  const attorneys = state.queue.attorneysOfJudge;
  const attorneysByCssId = _.keyBy(attorneys, 'css_id');

  return _.reduce(tasks, (appealsByUserId, task) => {
    const appealCssId = task.assignedTo.cssId;
    const attorney = attorneysByCssId[appealCssId];

    if (!attorney) {
      return appealsByUserId;
    }

    appealsByUserId[attorney.id] = [...(appealsByUserId[attorney.id] || []), task];

    return appealsByUserId;
  }, {});
};
