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

const getTasks = (state: State) => state.queue.tasks;
const getAppeals = (state: State) => state.queue.appeals;
const getUserCssId = (state: State) => state.ui.userCssId;

export const unassignedTasksSelector = createSelector(
  [getTasks],
  (tasks: Tasks) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.task_type === 'Assign'),
    (task: Task) => task.id
  )
);

export const tasksByAssigneeCssIdSelector = createSelector(
  [getTasks, getUserCssId],
  (tasks: Tasks, cssId: string) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.user_id === cssId),
    (task: Task) => task.id
  )
);

export const judgeReviewTasksSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks: Tasks) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.task_type === 'Review'),
    (task: Task) => task.id
  )
);

export const appealsByAssignedTaskSelector = createSelector(
  [getAppeals, tasksByAssigneeCssIdSelector],
  (appeals: LegacyAppeals, tasks: Tasks) => {
    const assignedAppealIds = _.map(tasks, (task: Task) => task.appealId);

    return _.keyBy(
      _.filter(appeals, (appeal: LegacyAppeal) => assignedAppealIds.includes(appeal.attributes.vacols_id)),
      (appeal: LegacyAppeal) => appeal.attributes.vacols_id
    );
  }
);

export const appealsWithTasks = createSelector(
  [getTasks, getAppeals],
  (tasks: Tasks, appeals: LegacyAppeals) => {
    taskMap = tasks.reduce((map, task) => {
      const taskList = map[task.appeal_id] ? [...map[task.appeal_id], task] : [task]
      return {...map, [task.appeal_id]: taskList}
    }, {});

    return appeals.map((appeal) => {
      appeal.tasks = taskMap[appeal.id]
    })
  }
);
