export const CavcAppealTaskTypes = [
  'SendCavcRemandProcessedLetterTask',
  'CavcRemandProcessedLetterResponseWindowTask',
  'IhpColocatedTask',
  'FoiaRequestMailTask',
  'FoiaTask',
  'FoiaColocatedTask',
]

export const taskTypesSelected = ({ tasks, selectedTaskIds }) => {
  return tasks.filter((task) => selectedTaskIds.includes(parseInt(task.taskId, 10))).map((task) => task.type);
};

// The following governs what should always be programmatically disabled from selection
export const alwaysDisabled = ['DistributionTask'];

export const shouldDisable = (taskInfo) => {
  return (CavcAppealTaskTypes.includes(taskInfo.type) || taskInfo.type === 'MdrTask');
};

export const shouldDisableCancelOrCompleted = (taskInfo) => {
  return [...CavcAppealTaskTypes, 'MdrTask'].includes(taskInfo.type);
};

export const shouldAutoSelect = (taskInfo) => {
  return !(CavcAppealTaskTypes.includes(taskInfo.type));
};
export const shouldAutoSelectCancelOrCompleted = (taskInfo) => {
  return ['SendCavcRemandProcessedLetterTask'].includes(taskInfo.type);
};

// Takes an array of tasks and filters it down to a list of most recent of each type
export const filterTasks = (taskData = [], opts = { orgOnly: true, closedOnly: true }) => {
  const uniqueTasksByType = {};

  for (const task of taskData) {
    // we only want organization tasks
    if (opts.orgOnly && !task.assignedTo?.isOrganization) {
      // eslint-disable-next-line no-continue
      continue;
    }

    // we only want completed and cancelled tasks
    if (opts.closedOnly && !task.closedAt) {
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

export const sortTasks = (taskData, sortField = 'closedAt') => {
  return taskData.sort((task1, task2) =>
    task1[sortField] > task2[sortField] ? -1 : 1
  );
};

export const filterOpenTasks = (tasks) => tasks.filter((task) => {
  return ['assigned', 'on_hold'].includes(task.status);
});

export const filterCancelOrCompletedTasks = (tasks) => tasks.filter((task) => {
  return ['completed', 'cancelled'].includes(task.status);
});

export const filterByCavcTasks = (tasks) => tasks.filter((task) => {
  return [...CavcAppealTaskTypes, 'MdrTask'].includes(task.type);
});

export const openTaskDataForUi = ({ taskData }) => {
  const tasks = filterByCavcTasks(taskData);
  const activeTasks = filterOpenTasks(tasks);
  const uniqTasks = filterTasks(activeTasks, { orgOnly: false, closedOnly: false });

  const sortedTasks = sortTasks(uniqTasks, 'createdAt');
  return sortedTasks.map((taskInfo) => ({
    ...taskInfo,
    disabled: shouldDisable(taskInfo),
    selected: shouldAutoSelect(taskInfo),
  }));
};

export const cancelledOrCompletedTasksDataForUi = ({ taskData }) => {
  const tasks = filterByCavcTasks(taskData);
  const inActiveTasks = filterCancelOrCompletedTasks(tasks);
  const uniqTasks = filterTasks(inActiveTasks);
  const sortedTasks = sortTasks(uniqTasks, 'closedAt');

  return sortedTasks.map((taskInfo) => ({
    ...taskInfo,
    disabled: shouldDisableCancelOrCompleted(taskInfo),
    selected: shouldAutoSelectCancelOrCompleted(taskInfo),
  }));
};
