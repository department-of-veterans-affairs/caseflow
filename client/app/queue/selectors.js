// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';

import type { State } from './types/state';
import type {
  Task,
  Tasks,
  AmaTask,
  AmaTasks,
  LegacyAppeal,
  LegacyAppeals,
  User
} from './types/models';

export const selectedTasksSelector = (state: State, userId: string) => _.flatMap(
  state.queue.isTaskAssignedToUserSelected[userId] || {},
  (selected, id) => selected ? [state.queue.tasks[id]] : []
);

const getTasks = (state: State) => state.queue.tasks;
const getAmaTasks = (state: State) => state.queue.amaTasks;
const getAppeals = (state: State) => state.queue.appeals;
const getUserCssId = (state: State) => state.ui.userCssId;

export const tasksByAssigneeCssIdSelector = createSelector(
  [getTasks, getUserCssId],
  (tasks: Tasks, cssId: string) => _.keyBy(
    _.filter(tasks, (task: Task) => task.attributes.user_id === cssId),
    (task: Task) => task.id
  )
);

export const amaTasksByAssigneeId: (State) => { [number]: AmaTask } = createSelector(
  [getAmaTasks],
  (tasks: AmaTasks) => _.groupBy(tasks, (task) => task.attributes.assigned_to.id)
);

export const appealsWithTasksSelector = createSelector(
  [getTasks, getAppeals],
  (tasks: Tasks, appeals: LegacyAppeals) => {
    const taskMap = _.reduce(tasks, (map, task) => {
      const taskList = map[task.attributes.appeal_id] ? [...map[task.attributes.appeal_id], task] : [task];

      return { ...map,
        [task.attributes.appeal_id]: taskList };
    }, {});

    return _.map(appeals, (appeal) => {
      appeal.tasks = taskMap[appeal.id];

      return appeal;
    });
  }
);

export const appealsByAssigneeCssIdSelector = createSelector(
  [appealsWithTasksSelector, getUserCssId],
  (appeals: LegacyAppeals, cssId: string) =>
    _.filter(appeals, (appeal: LegacyAppeal) =>
      _.some(appeal.tasks, (task) => task.attributes.user_id === cssId))
);

export const judgeReviewAppealsSelector = createSelector(
  [appealsByAssigneeCssIdSelector],
  (appeals: LegacyAppeals) =>
    _.filter(appeals, (appeal: LegacyAppeal) => appeal.tasks &&
      _.some(appeal.tasks, (task) => task.attributes.task_type === 'Review'))
);

export const judgeAssignAppealsSelector = createSelector(
  [appealsByAssigneeCssIdSelector],
  (appeals: LegacyAppeals) =>
    _.filter(appeals, (appeal: LegacyAppeal) => appeal.tasks &&
      _.some(appeal.tasks, (task) => task.attributes.task_type === 'Assign'))
);

// ***************** Non-memoized selectors *****************

const getAttorney = (state: State, attorneyId: string) => {
  if (!state.queue.attorneysOfJudge) {
    return null;
  }

  return _.find(state.queue.attorneysOfJudge, (attorney: User) => attorney.id.toString() === attorneyId);
};

export const getAssignedAppeals = (state: State, attorneyId: string) => {
  const appeals = appealsWithTasksSelector(state);
  const attorney = getAttorney(state, attorneyId);
  const cssId = attorney ? attorney.css_id : null;

  return _.filter(appeals, (appeal: LegacyAppeal) =>
    _.some(appeal.tasks, (task) => task.attributes.user_id === cssId));
};

export const getAppealsByUserId = (state: State) => {
  const appeals = appealsWithTasksSelector(state);
  const attorneys = state.queue.attorneysOfJudge;
  const attorneysByCssId = _.keyBy(attorneys, 'css_id');

  return _.reduce(appeals, (appealsByUserId: Object, appeal: LegacyAppeal) => {
    const appealCssId = appeal.tasks ? appeal.tasks[0].attributes.user_id : null;
    const attorney = attorneysByCssId[appealCssId];

    if (!attorney) {
      return appealsByUserId;
    }

    appealsByUserId[attorney.id] = [...(appealsByUserId[attorney.id] || []), appeal];

    return appealsByUserId;
  }, {});
};
