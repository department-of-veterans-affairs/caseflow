// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';
import {
  taskHasNewDocuments,
  taskIsOnHold
} from './utils';

import type {
  State,
  NewDocsForAppeal,
  UiStateModals
} from './types/state';
import type {
  Task,
  Tasks,
  TaskWithAppeal,
  Appeal,
  Appeals,
  BasicAppeals,
  AppealDetails,
  User
} from './types/models';
import TASK_STATUSES from '../../constants/TASK_STATUSES.json';

export const selectedTasksSelector = (state: State, userId: string) => {
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

const getTasks = (state: State): Tasks => state.queue.tasks;
const getAmaTasks = (state: State): Tasks => state.queue.amaTasks;
const getAppeals = (state: State): BasicAppeals => state.queue.appeals;
const getAppealDetails = (state: State): AppealDetails => state.queue.appealDetails;
const getUserCssId = (state: State): string => state.ui.userCssId;
const getAppealId = (state: State, props: Object): string => props.appealId;
const getActiveOrganizationId = (state: State): ?number => state.ui.activeOrganizationId;
const getTaskUniqueId = (state: State, props: Object): string => props.taskId;
const getCaseflowVeteranId = (state: State, props: Object): ?string => props.caseflowVeteranId;
const getModals = (state: State): UiStateModals => state.ui.modals;
const getNewDocsForAppeal = (state: State): NewDocsForAppeal => state.queue.newDocsForAppeal;

const incompleteTasksSelector = (tasks: Tasks | Array<Task>) =>
  _.filter(tasks, (task) => task.status !== TASK_STATUSES.completed);
const completeTasksSelector = (tasks: Tasks) => _.filter(tasks, (task) => task.status === TASK_STATUSES.completed);

export const getActiveModalType = createSelector(
  [getModals],
  (modals: { String: boolean }) => _.find(Object.keys(modals), (modalName) => modals[modalName])
);

export const tasksWithAppealSelector = createSelector(
  [getTasks, getAmaTasks, getAppeals, getAppealDetails],
  (tasks: Tasks, amaTasks: Tasks, appeals: BasicAppeals, appealDetails: AppealDetails) : Array<TaskWithAppeal> => {
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

export const tasksByOrganization = createSelector(
  [tasksWithAppealSelector, getActiveOrganizationId],
  (tasks: Array<TaskWithAppeal>, organizationId: string) =>
    _.filter(tasks, (task) => (task.assignedTo.id === organizationId))
);

export const taskById = createSelector(
  [tasksWithAppealSelector, getTaskUniqueId],
  (tasks: Array<TaskWithAppeal>, taskId: string) =>
    _.find(tasks, (task) => task.uniqueId === taskId)
);

export const appealsWithDetailsSelector = createSelector(
  [getAppeals, getAppealDetails],
  (appeals: BasicAppeals, appealDetails: Appeals) => {
    return _.merge(appeals, appealDetails);
  }
);

export const appealWithDetailSelector = createSelector(
  [appealsWithDetailsSelector, getAppealId],
  (appeals: Appeals, appealId: string) => appeals[appealId]
);

export const getTasksForAppeal = createSelector(
  [getTasks, getAmaTasks, getAppealId],
  (tasks: Tasks, amaTasks: Tasks, appealId: string) => {
    return incompleteTasksSelector(_.filter(tasks, (task) => task.externalAppealId === appealId).
      concat(_.filter(amaTasks, (task) => task.externalAppealId === appealId)));
  }
);

export const getUnassignedOrganizationalTasks = createSelector(
  [tasksWithAppealSelector],
  (tasks: Tasks) => _.filter(tasks, (task) => {
    return (task.status === TASK_STATUSES.assigned || task.status === TASK_STATUSES.in_progress);
  })
);

export const getAssignedOrganizationalTasks = createSelector(
  [tasksWithAppealSelector],
  (tasks: Tasks) => _.filter(tasks, (task) => (task.status === TASK_STATUSES.on_hold))
);

export const getCompletedOrganizationalTasks = createSelector(
  [tasksWithAppealSelector],
  (tasks: Tasks) => _.filter(tasks, (task) => task.status === TASK_STATUSES.completed)
);

export const tasksForAppealAssignedToUserSelector = createSelector(
  [getTasksForAppeal, getUserCssId],
  (tasks: Tasks, cssId: string) => {
    return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
  }
);

export const appealsByCaseflowVeteranId = createSelector(
  [appealsWithDetailsSelector, getCaseflowVeteranId],
  (appeals: Appeals, caseflowVeteranId: ?string) =>
    _.filter(appeals, (appeal: Appeal) => appeal.caseflowVeteranId && caseflowVeteranId &&
      appeal.caseflowVeteranId.toString() === caseflowVeteranId.toString())
);

export const tasksByAssigneeCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks: Array<TaskWithAppeal>, cssId: string) =>
    _.filter(tasks, (task) => task.assignedTo.cssId === cssId)
);

export const tasksByAssignerCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks: Array<TaskWithAppeal>, cssId: string) =>
    _.filter(tasks, (task) => task.assignedBy.cssId === cssId)
);

export const incompleteTasksByAssigneeCssIdSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks: Tasks) => incompleteTasksSelector(tasks)
);

export const incompleteTasksByAssignerCssIdSelector = createSelector(
  [tasksByAssignerCssIdSelector],
  (tasks: Tasks) => incompleteTasksSelector(tasks)
);

export const completeTasksByAssigneeCssIdSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks: Tasks) => completeTasksSelector(tasks)
);

export const actionableTasksForAppeal = createSelector(
  [getTasksForAppeal], (tasks: Tasks) => _.filter(tasks, (task) => task.availableActions.length)
);

export const rootTaskForAppeal = createSelector(
  [getTasksForAppeal], (tasks: Tasks) => _.filter(tasks, (task) => task.type == 'RootTask')
);

export const newTasksByAssigneeCssIdSelector = createSelector(
  [incompleteTasksByAssigneeCssIdSelector],
  (tasks: Array<Task>) => tasks.filter((task) => !taskIsOnHold(task))
);

export const workableTasksByAssigneeCssIdSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks: Array<TaskWithAppeal>) => tasks.filter(
    (task) => {
      return (task.appeal.isLegacyAppeal ||
          task.status === TASK_STATUSES.assigned ||
          task.status === TASK_STATUSES.in_progress);
    }
  )
);

const incompleteTasksWithHold: (State) => Array<Task> = createSelector(
  [incompleteTasksByAssigneeCssIdSelector],
  (tasks: Array<Task>) => tasks.filter((task) => taskIsOnHold(task))
);

export const pendingTasksByAssigneeCssIdSelector: (State) => Array<Task> = createSelector(
  [incompleteTasksWithHold, getNewDocsForAppeal],
  (tasks: Array<Task>, newDocsForAppeal: NewDocsForAppeal) => tasks.filter((task) =>
    !taskIsOnHold(task) || taskHasNewDocuments(task, newDocsForAppeal)
  )
);

export const onHoldTasksByAssigneeCssIdSelector: (State) => Array<Task> = createSelector(
  [incompleteTasksWithHold, getNewDocsForAppeal],
  (tasks: Array<Task>, newDocsForAppeal: NewDocsForAppeal) => tasks.filter((task) =>
    taskIsOnHold(task) && !taskHasNewDocuments(task, newDocsForAppeal)
  )
);

export const onHoldTasksForAttorney: (State) => Array<Task> = createSelector(
  [incompleteTasksWithHold, incompleteTasksByAssignerCssIdSelector],
  (incompleteWithHold: Array<Task>, incompleteByAssigner: Array<Task>) => {
    const onHoldTasksWithDuplicates = incompleteWithHold.concat(incompleteByAssigner);

    return _.filter(onHoldTasksWithDuplicates, (task) => task.assignedTo.type === 'User');
  }
);

export const judgeReviewTasksSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) => _.filter(tasks, (task: TaskWithAppeal) => {
    if (task.appealType === 'Appeal') {
      return task.label === 'review' &&
        (task.status === TASK_STATUSES.in_progress || task.status === TASK_STATUSES.assigned);
    }

    // eslint-disable-next-line no-undefined
    return [null, undefined, 'review'].includes(task.label);
  })
);

export const judgeAssignTasksSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) => _.filter(tasks, (task: TaskWithAppeal) => {
    if (task.appealType === 'Appeal') {
      return task.label === 'assign' &&
        (task.status === TASK_STATUSES.in_progress || task.status === TASK_STATUSES.assigned);
    }

    return task.label === 'assign';
  })
);

// ***************** Non-memoized selectors *****************

const getAttorney = (state: State, attorneyId: string) => {
  if (!state.queue.attorneysOfJudge) {
    return null;
  }

  return _.find(state.queue.attorneysOfJudge, (attorney: User) => attorney.id.toString() === attorneyId);
};

export const getAssignedTasks = (state: State, attorneyId: string) => {
  const tasks = incompleteTasksSelector(tasksWithAppealSelector(state));
  const attorney = getAttorney(state, attorneyId);
  const cssId = attorney ? attorney.css_id : null;

  return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
};

export const getTasksByUserId = (state: State) => {
  const tasks = incompleteTasksSelector(tasksWithAppealSelector(state));
  const attorneys = state.queue.attorneysOfJudge;
  const attorneysByCssId = _.keyBy(attorneys, 'css_id');

  return _.reduce(tasks, (appealsByUserId: Object, task: Task) => {
    const appealCssId = task.assignedTo.cssId;
    const attorney = attorneysByCssId[appealCssId];

    if (!attorney) {
      return appealsByUserId;
    }

    appealsByUserId[attorney.id] = [...(appealsByUserId[attorney.id] || []), task];

    return appealsByUserId;
  }, {});
};
