// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';

import type { State } from './types/state';
import type {
  Task,
  Tasks,
  LegacyAppeal,
  LegacyAppeals
} from './types/models';

export const selectedTasksSelector = (state: State, userId: string) => _.flatMap(
  state.queue.isTaskAssignedToUserSelected[userId] || {},
  (selected, id) => selected ? [state.queue.tasks[id]] : []
);

const getTasks = (state: State): Tasks => state.queue.tasks;
const getAppeals = (state: State): LegacyAppeals => state.queue.appeals;
const getUserCssId = (state: State): string => state.ui.userCssId;

export const unassignedTasksSelector = createSelector(
  [getTasks],
  (tasks: Tasks) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.task_type === 'Assign'),
    (task: Task) => task.id
  )
);

export const tasksByAssigneeCssId = createSelector(
  [getTasks, getUserCssId],
  (tasks: Tasks, cssId: string) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.user_id === cssId),
    (task: Task) => task.id
  )
);

export const judgeReviewTasksSelector = createSelector(
  [tasksByAssigneeCssId],
  (tasks: Tasks) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.task_type === 'Review'),
    (task: Task) => task.id
  )
);

export const appealsByLocationCodeSelector = createSelector(
  [getAppeals, getUserCssId],
  (appeals: LegacyAppeals, cssId: string) => _.keyBy(
    _.filter(appeals, (appeal: LegacyAppeal) => cssId.includes(appeal.attributes.location_code)),
    (appeal: LegacyAppeal) => appeal.attributes.vacols_id
  )
);
