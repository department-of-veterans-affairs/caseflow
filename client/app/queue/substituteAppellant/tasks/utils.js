import { formatISO, startOfDay } from 'date-fns';
import parseISO from 'date-fns/parseISO';

export const automatedTasks = [
  'QualityReviewTask',
  'JudgeQualityReviewTask',
  'AttorneyQualityReviewTask',
  'JudgeAssignTask',
  'JudgeDecisionReviewTask',
  'AttorneyTask',
  'AttorneyRewriteTask',
  'BvaDispatchTask',
  'JudgeDispatchReturnTask',
  'AttorneyDispatchReturnTask',
  'HearingTask'
];

// Generic function to determine if a task (`current`) is a descendent of another task (`target`)
// allItems is object keyed to a specified id
export const isDescendant = (
  allItems = {},
  target,
  current,
  { id = 'taskId' } = {}
) => {
  if (!current?.parentId) {
    return false;
  }

  if (target[id] === current.parentId) {
    return true;
  }

  const parent = allItems[current.parentId];

  return isDescendant(allItems, target, parent, { id });
};

// The following can be used to programmatically determine if a given task
// is a (nested) child of the Distribution Task
export const isDescendantOfDistributionTask = (taskId, taskList) => {
  let distributionTask, task;

  // Loop only once for efficiency
  for (const item of taskList) {
    if (item.type === 'DistributionTask') {
      distributionTask = item;
    }
    if (item.taskId === taskId) {
      task = item;
    }
    // Stop as soon as we have both
    if (distributionTask && task) {
      break;
    }
  }

  if (!distributionTask) {
    return false;
  }

  // isDescendent takes keyed object rather than array for performance reasons
  const tasksById = taskList.reduce(
    (acc, curr) => ({ ...acc, [curr.taskId]: curr }),
    {}
  );

  return isDescendant(tasksById, distributionTask, task, { id: 'taskId' });
};

export const taskTypesSelected = ({ tasks, selectedTaskIds }) => {
  return tasks.filter((task) => selectedTaskIds.includes(parseInt(task.taskId, 10))).map((task) => task.type);
};

export const shouldDisableBasedOnTaskType = (taskType, selectedTaskTypes) => {
  const disablingTaskMap = {
    ScheduleHearingTask: [
      'AssignHearingDispositionTask',
      'ChangeHearingDispositionTask',
      'EvidenceSubmissionWindowTask',
      'TranscriptionTask',
    ],
    EvidenceSubmissionWindowTask: [
      'ScheduleHearingTask',
      'AssignHearingDispositionTask',
      'ChangeHearingDispositionTask',
    ],
    TranscriptionTask: [
      'ScheduleHearingTask',
      'AssignHearingDispositionTask',
      'ChangeHearingDispositionTask',
    ],
  };

  return Object.entries(disablingTaskMap).some(([selectionType, toDisable]) => {
    return selectedTaskTypes.includes(selectionType) && toDisable.includes(taskType);
  });
};

// The following governs what should always be programmatically disabled from selection
export const alwaysDisabled = ['DistributionTask'];

export const shouldDisable = (taskInfo) => {
  return alwaysDisabled.includes(taskInfo.type);
};

export const disabledTasksBasedOnSelections = ({ tasks, selectedTaskIds }) => {
  const selectedTaskTypes = taskTypesSelected({ tasks, selectedTaskIds });

  return tasks.map((task) => {
    return ({
      ...task,
      disabled: shouldDisable(task) || shouldDisableBasedOnTaskType(task.type, selectedTaskTypes)
    });
  });
};

export const shouldHideBasedOnPoa = (taskInfo, claimantPoa) => {
  // eslint-disable-next-line camelcase
  return taskInfo.type === 'InformalHearingPresentationTask' && !claimantPoa?.ihp_allowed;
};

// We can have a case where a particular task's inclusion depends upon other tasks
// This happens with org tasks that are normally hidden from case timeline
// but corresponding user tasks would be shown
export const shouldShowBasedOnOtherTasks = (taskInfo, allTasks) => {
  const taskType = taskInfo.type;

  // eslint-disable-next-line max-len
  const visibleUserTask = allTasks.find((item) => item.type === taskType && item.taskId !== taskInfo.taskId && !item.assignedTo?.isOrganization && !item.hideFromCaseTimeline);

  return Boolean(visibleUserTask);
};

// The following governs which tasks should not actually appear in list of available tasks
export const shouldHide = (taskInfo, claimantPoa, allTasks) => {
  if (automatedTasks.includes(taskInfo.type)) {
    return true;
  }

  // eslint-disable-next-line max-len
  return (taskInfo.hideFromCaseTimeline || shouldHideBasedOnPoa(taskInfo, claimantPoa)) && !shouldShowBasedOnOtherTasks(taskInfo, allTasks);
};

export const shouldAutoSelect = (taskInfo) => {
  return ['DistributionTask'].includes(taskInfo.type);
};

// Takes an array of tasks and filters it down to a list of most recent of each type
export const filterTasks = (taskData = []) => {
  const uniqueTasksByType = {};

  for (const task of taskData) {
    // we only want organization tasks
    if (!task.assignedTo?.isOrganization) {
      // eslint-disable-next-line no-continue
      continue;
    }

    // we only want completed and cancelled tasks
    if (!task.closedAt) {
      // eslint-disable-next-line no-continue
      continue;
    }

    const newer = uniqueTasksByType[task.type]?.closedAt > task.closedAt;

    // If unrepresented or is newer, add to object
    if (!newer) {
      uniqueTasksByType[task.type] = task;
    }
  }

  return Object.values(uniqueTasksByType);
};

export const sortTasks = (taskData) => {
  return taskData.sort((task1, task2) =>
    task1.closedAt > task2.closedAt ? -1 : 1
  );
};

// This returns array of tasks with relevant booleans for hidden/disabled
export const prepTaskDataForUi = (taskData, claimantPoa) => {
  const uniqTasks = filterTasks(taskData);

  const sortedTasks = sortTasks(uniqTasks);

  return sortedTasks.map((taskInfo) => ({
    ...taskInfo,
    hidden: shouldHide(taskInfo, claimantPoa, taskData),
    disabled: shouldDisable(taskInfo),
    selected: shouldAutoSelect(taskInfo),
  }));
};

export const calculateEvidenceSubmissionEndDate = ({
  substitutionDate: substitutionDateStr,
  veteranDateOfDeath: veteranDateOfDeathStr,
  selectedTasks,
}) => {
  const substitutionDate = parseISO(substitutionDateStr);
  const veteranDateOfDeath = parseISO(veteranDateOfDeathStr);
  const evidenceSubmissionTask = selectedTasks.find(
    (task) => task.type === 'EvidenceSubmissionWindowTask'
  );

  if (!evidenceSubmissionTask?.timerEndsAt) {
    return null;
  }
  const timerEndsAt = evidenceSubmissionTask.timerEndsAt;
  const timerEndsAtDate = parseISO(timerEndsAt);

  let remainingTime = timerEndsAtDate.getTime() - veteranDateOfDeath.getTime();

  // Convert days to milliseconds
  const maxEvidenceSubmissionWindow = 90 * 86400000;

  if (remainingTime > maxEvidenceSubmissionWindow) {
    remainingTime = maxEvidenceSubmissionWindow;
  }

  const newEndTime = substitutionDate.getTime() + remainingTime;

  // We want to specify midnight in user's time zone (likely Eastern)
  return formatISO(startOfDay(new Date(newEndTime)));
};
