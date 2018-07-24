// @flow
import { createSelector, createSelectorCreator, defaultMemoize } from 'reselect';
import _ from 'lodash';

import type { State } from './types/state';
import type {
  Task,
  Tasks,
  LegacyAppeal,
  LegacyAppeals,
  Attorneys
} from './types/models';

export const selectedTasksSelector = (state: State, userId: string) => _.flatMap(
  state.queue.isTaskAssignedToUserSelected[userId] || {},
  (selected, id) => selected ? [state.queue.tasks[id]] : []
);

const createDeepEqualSelector = createSelectorCreator(
  defaultMemoize,
  _.isEqual
)

const getTasks = (state: State) => state.queue.tasks;
const getAppeals = (state: State) => state.queue.appeals;
const getUserCssId = (state: State) => state.ui.userCssId;
const getAttorney = (state: State, attorneyId: string) => {
  if (!state.queue.attorneysOfJudge) {
    return null;
  }

  return _.find(state.queue.attorneysOfJudge, (attorney) => attorney.id.toString() === attorneyId);
}
export const tasksByAssigneeCssIdSelector = createSelector(
  [getTasks, getUserCssId],
  (tasks: Tasks, cssId: string) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.user_id === cssId),
    (task: Task) => task.id
  )
);

export const appealsWithTasks = createDeepEqualSelector(
  [getTasks, getAppeals],
  (tasks: Tasks, appeals: LegacyAppeals) => {
    const taskMap = _.reduce(tasks, (map, task) => {
      const taskList = map[task.attributes.appeal_id] ? [...map[task.attributes.appeal_id], task] : [task]
      return {...map, [task.attributes.appeal_id]: taskList}
    }, {});

    return _.map(appeals, (appeal) => {
      appeal.tasks = taskMap[appeal.id];

      return appeal;
    })
  }
);

export const appealsByAssigneeCssIdSelector = createSelector(
  [appealsWithTasks, getUserCssId],
  (appeals: LegacyAppeals, cssId: string) => 
    _.values(_.filter(appeals, (appeal: LegacyAppeal) => _.some(appeal.tasks, (task) => task.attributes.user_id === cssId)))
);

export const judgeReviewAppealsSelector = createSelector(
  [appealsByAssigneeCssIdSelector],
  (appeals: LegacyAppeals) =>
    _.filter(appeals, (appeal: LegacyAppeal) => appeal.tasks[0].attributes.task_type === 'Review')
);

export const unassignedAppealsSelector = createSelector(
  [appealsWithTasks],
  (appeals: LegacyAppeals) =>
    _.filter(appeals, (appeal: LegacyAppeal) => appeal.tasks[0].attributes.task_type === 'Assign')
);

export const assignedAppealsSelector = createDeepEqualSelector(
  [appealsWithTasks, getAttorney],
  (appeals: LegacyAppeals, attorney: Attorneys) => {
    const cssId = attorney ? attorney.css_id : null;

    return _.filter(appeals, (appeal: LegacyAppeal) =>
      _.some(appeal.tasks, (task) => task.attributes.user_id === cssId))
  }
);
