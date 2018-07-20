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