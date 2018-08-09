// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';

import type { State } from './types/state';
import type {
  Appeal,
  Appeals,
  Task,
  Tasks,
  AmaTask,
  AmaTasks,
  LegacyAppeal,
  LegacyAppeals,
  User
} from './types/models';

export const selectedTasksSelector = (state: State, userId: string) => {
  return _.flatMap(
    state.queue.isTaskAssignedToUserSelected[userId] || {},
    (selected, id) => selected ? [state.queue.tasks[id]] : []
  );
};

const getTasks = (state: State) => state.queue.tasks;
const getAmaTasks = (state: State) => state.queue.amaTasks;
const getAppeals = (state: State) => state.queue.appeals;
const getAppealDetails = (state: State) => state.queue.appealDetails;
const getUserCssId = (state: State) => state.ui.userCssId;
const getAppealId = (state: State, props: Object) => props.appealId;
const getAttorneys = (state: State) => state.queue.attorneysOfJudge;
const getCaseflowVeteranId = (state: State, props: Object) => props.caseflowVeteranId;

export const tasksByAssigneeCssIdSelector = createSelector(
  [getTasks, getUserCssId],
  (tasks: Tasks, cssId: string) => _.keyBy(
    _.filter(tasks, (task: Task) => task.userId === cssId),
    (task: Task) => task.taskId
  )
);

export const amaTasksByAssigneeId: (State) => { [number]: AmaTask } = createSelector(
  [getAmaTasks],
  (tasks: AmaTasks) => _.groupBy(tasks, (task) => task.attributes.assigned_to.id)
);

export const appealsWithTasksSelector = createSelector(
  [getTasks, getAppeals],
  (tasks: Tasks, appeals: LegacyAppeals) => {
    return _.map(appeals, (appeal) => {
      return { ...appeal,
        tasks: _.filter(tasks, (task) => task.externalAppealId === appeal.externalId) };
    });
  }
);

export const getTasksForAppeal = createSelector(
  [getTasks, getAppealId],
  (tasks: Tasks, appealId: number) => {
    return _.filter(tasks, (task) => task.externalAppealId === appealId);
  }
);

export const tasksForAppealAssignedToUserSelector = createSelector(
  [getTasksForAppeal, getUserCssId],
  (tasks: Tasks, cssId: string) => {
    return _.filter(tasks, (task) => task.userId === cssId);
  }
);

export const tasksForAppealAssignedToAttorneySelector = createSelector(
  [getTasksForAppeal, getAttorneys],
  (tasks: Tasks, attorneys: Array<User>) => {
    return _.filter(tasks, (task) => _.some(attorneys, (attorney) => task.userId === attorney.css_id));
  }
);

export const appealsByCaseflowVeteranId = createSelector(
  [getAppealDetails, getCaseflowVeteranId],
  (appeals: Appeals, caseflowVeteranId: string) =>
    _.filter(appeals, (appeal: Appeal) => appeal.attributes.caseflow_veteran_id &&
      appeal.attributes.caseflow_veteran_id.toString() === caseflowVeteranId.toString())
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
