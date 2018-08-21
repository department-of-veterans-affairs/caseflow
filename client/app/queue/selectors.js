// @flow
import { createSelector } from 'reselect';
import _ from 'lodash';
import moment from 'moment';

import type { State, NewDocsForAppeal } from './types/state';
import type {
  Task,
  Tasks,
  TaskWithAppeal,
  Appeal,
  Appeals,
  BasicAppeals,
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

export const tasksWithAppealSelector = createSelector(
  [getTasks, getAmaTasks, getAppeals],
  (tasks: Tasks, amaTasks: Tasks, appeals: Appeals) : Array<TaskWithAppeal> => {
    return [
      ..._.map(tasks, (task) => {
        return { ...task,
          appeal: _.find(appeals, (appeal) => task.externalAppealId === appeal.externalId)
        };
      }),
      ..._.map(amaTasks, (amaTask) => {
        return { ...amaTask,
          appeal: _.find(appeals, (appeal) => amaTask.externalAppealId === appeal.externalId)
        };
      })
    ];
  }
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
    return _.filter(tasks, (task) => task.externalAppealId === appealId).
      concat(_.filter(amaTasks, (task) => task.externalAppealId === appealId));
  }
);

export const tasksForAppealAssignedToUserSelector = createSelector(
  [getTasksForAppeal, getUserCssId],
  (tasks: Tasks, cssId: string) => {
    return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
  }
);

export const tasksForAppealAssignedToAttorneySelector = createSelector(
  [getTasksForAppeal, getAttorneys],
  (tasks: Tasks, attorneys: Array<User>) => {
    return _.filter(tasks, (task) => _.some(attorneys, (attorney) => task.assignedTo.cssId === attorney.css_id));
  }
);

export const appealsByCaseflowVeteranId = createSelector(
  [appealsWithDetailsSelector, getCaseflowVeteranId],
  (appeals: Appeals, caseflowVeteranId: string) =>
    _.filter(appeals, (appeal: Appeal) => appeal.caseflowVeteranId &&
      appeal.caseflowVeteranId.toString() === caseflowVeteranId.toString())
);

export const tasksByAssigneeCssIdSelector = createSelector(
  [tasksWithAppealSelector, getUserCssId],
  (tasks: Array<Task>, cssId: string) =>
    _.filter(tasks, (task) => task.assignedTo.cssId === cssId)
);

export const newTasksByAssigneeCssIdSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks: Array<Task>) => tasks.filter((task) => !task.placedOnHoldAt)
);

const getNewDocsForAppeal = (state: State) => state.queue.newDocsForAppeal;

export const onHoldTasksByAssigneeCssIdSelector: (State) => Array<Task> = createSelector(
  [tasksByAssigneeCssIdSelector, getNewDocsForAppeal],
  (tasks: Array<Task>, newDocsForAppeal: NewDocsForAppeal) =>
    tasks.filter((task) => moment().diff(moment(task.placedOnHoldAt), 'days') < task.onHoldDuration && (!newDocsForAppeal[task.externalAppealId] || newDocsForAppeal[task.externalAppealId].length == 0))
);

export const judgeReviewTasksSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) =>
    _.filter(tasks, (task: Task) => task.taskType === 'Review' || task.taskType === null)
);

export const judgeAssignTasksSelector = createSelector(
  [tasksByAssigneeCssIdSelector],
  (tasks) => _.filter(tasks, (task) => task.taskType === 'Assign')
);

// ***************** Non-memoized selectors *****************

const getAttorney = (state: State, attorneyId: string) => {
  if (!state.queue.attorneysOfJudge) {
    return null;
  }

  return _.find(state.queue.attorneysOfJudge, (attorney: User) => attorney.id.toString() === attorneyId);
};

export const getAssignedTasks = (state: State, attorneyId: string) => {
  const tasks = tasksWithAppealSelector(state);
  const attorney = getAttorney(state, attorneyId);
  const cssId = attorney ? attorney.css_id : null;

  return _.filter(tasks, (task) => task.assignedTo.cssId === cssId);
};

export const getTasksByUserId = (state: State) => {
  const tasks = tasksWithAppealSelector(state);
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
