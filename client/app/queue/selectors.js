// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';

import type { State } from './types/state';
import type {
  Task,
  Tasks,
  LegacyAppeal,
  LegacyAppeals,
  User
} from './types/models';

export const selectedTasksSelector = (state: State, userId: string) => {
  const flatTasks = _.flatten(_.values(state.queue.tasks));

  return _.flatMap(
    state.queue.isTaskAssignedToUserSelected[userId] || {},
    (selected, id) => selected ? [_.find(flatTasks, { taskId: id })] : []
  );
};

const getTasks = (state: State) => state.queue.tasks;
const getAppeals = (state: State) => state.queue.appeals;
const getUserCssId = (state: State) => state.ui.userCssId;
const getAppealId = (state: State, props: Object) => props.appealId;

export const tasksByAssigneeCssIdSelector = createSelector(
  [getTasks, getUserCssId],
  (tasks: Tasks, cssId: string) => _.keyBy(
    _.filter(tasks, (task: Task) => task.userId === cssId),
    (task: Task) => task.taskId
  )
);

export const appealsWithTasksSelector = createSelector(
  [getTasks, getAppeals],
  (tasks: Tasks, appeals: LegacyAppeals) => {
    return _.map(appeals, (appeal) => {
      appeal.tasks = _.filter(tasks, (task) => task.externalAppealId === appeal.externalId);

      return appeal;
    });
  }
);

export const tasksForAppealSelector = createSelector(
  [getTasks, getAppealId],
  (tasks: Tasks, appealId: number) => {
    return _.filter(tasks, (task) => task.externalAppealId === appealId);
  }
);

export const tasksForAppealAssignedToUserSelector = createSelector(
  [tasksForAppealSelector, getUserCssId],
  (tasks: Tasks, cssId: string) => {
    return _.filter(tasks, (task) => task.userId === cssId);
  }
);

export const appealsByAssigneeCssIdSelector = createSelector(
  [appealsWithTasksSelector, getUserCssId],
  (appeals: LegacyAppeals, cssId: string) =>
    _.filter(appeals, (appeal: LegacyAppeal) =>
      _.some(appeal.tasks, (task) => task.userId === cssId))
);

export const judgeReviewAppealsSelector = createSelector(
  [appealsByAssigneeCssIdSelector],
  (appeals: LegacyAppeals) =>
    _.filter(appeals, (appeal: LegacyAppeal) => appeal.tasks &&
      _.some(appeal.tasks, (task) => task.taskType === 'Review'))
);

export const judgeAssignAppealsSelector = createSelector(
  [appealsByAssigneeCssIdSelector],
  (appeals: LegacyAppeals) =>
    _.filter(appeals, (appeal: LegacyAppeal) => appeal.tasks &&
      _.some(appeal.tasks, (task) => task.taskType === 'Assign'))
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
    _.some(appeal.tasks, (task) => task.userId === cssId));
};

export const getAppealsByUserId = (state: State) => {
  const appeals = appealsWithTasksSelector(state);
  const attorneys = state.queue.attorneysOfJudge;
  const attorneysByCssId = _.keyBy(attorneys, 'css_id');

  return _.reduce(appeals, (appealsByUserId: Object, appeal: LegacyAppeal) => {
    const appealCssId = appeal.tasks ? appeal.tasks[0].userId : null;
    const attorney = attorneysByCssId[appealCssId];

    if (!attorney) {
      return appealsByUserId;
    }

    appealsByUserId[attorney.id] = [...(appealsByUserId[attorney.id] || []), appeal];

    return appealsByUserId;
  }, {});
};
