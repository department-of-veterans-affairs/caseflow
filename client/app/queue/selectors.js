// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';

import type { State } from './types/state';
import type {
  Tasks,
  LegacyAppeals
} from './types/models';

export const selectedTasksSelector = (state: State, userId: string) => _.flatMap(
  state.queue.isTaskAssignedToUserSelected[userId] || {},
  (selected, id) => selected ? [state.queue.tasks[id]] : []
);

const getTasks = (state: State): Tasks => state.queue.tasks;
const getAppeals = (state: State): LegacyAppeals => state.queue.appeals;

export const unassignedTasksSelector = createSelector(
  [getTasks],
  (tasks: Tasks) => _.keyBy(
    _.filter(tasks, (task) => task.attributes.task_type === 'Assign'),
    'id'
  )
);

export const judgeReviewTasksSelector = createSelector(
  [getTasks],
  (tasks: Tasks) => _.keyBy(
    _.filter(tasks, (task) => task.attributes.task_type === 'Review'),
    'id'
  )
);

// export const appealByAssigneeCssId = (state: State, css_id: string = '') => createSelector(
//   [getAppeals],
//   (appeal) => css_id.includes(appeal.attributes.location_code)
// );
