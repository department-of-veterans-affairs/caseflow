// Generic function to determine if a task is a descendent of another task
// allItems is object keyed to taskId
export const isDescendant = (allItems = {}, target, current, { id = 'id' } = {}) => {
  if (!current.parentId) {
    return false;
  }

  if (target[id] === current.parentId) {
    return true;
  }

  const parent = allItems[current.parentId];

  return isDescendant(allItems, target, parent);
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

// The following governs what should always be programmatically disabled from selection
export const alwaysDisabled = ['DistributionTask'];
export const shouldDisable = (taskInfo) => {
  if (alwaysDisabled.includes(taskInfo.type)) {
    return true;
  }

  return false;
};

// The following governs which tasks should not actually appear in list of available tasks
export const shouldHide = (taskInfo) => {
  // Currently honoring the same logic for hiding from Case Timeline
  // Can be used in the future to add specific task types (taskInfo.type) and/or descendents as needed
  return taskInfo.hideFromCaseTimeline;
};

export const shouldAutoSelect = (taskInfo) => {
  return taskInfo.type === 'DistributionTask';
};

// Takes an array of tasks and filters it down to a list of most recent of each type
export const filterDuplicateTasks = (taskData = []) => {
  const uniqueTasksByType = {};

  for (const task of taskData) {
    const newer = uniqueTasksByType[task.type]?.closedAt > task.closedAt;
    const isChild = task.parentId === uniqueTasksByType[task.type]?.taskId;

    // If unrepresented or is newer, add to object
    if (!newer) {
      uniqueTasksByType[task.type] = task;
    }

    // Prefer leaf nodes (likely user vs org)
    if (isChild) {
      uniqueTasksByType[task.type] = task;
    }
  }

  return Object.values(uniqueTasksByType);
};

// This returns array of tasks with relevant booleans for hidden/disabled
export const formatTaskData = (taskData) => {
  const uniqTasks = filterDuplicateTasks(taskData);

  return uniqTasks.map((taskInfo) => ({
    ...taskInfo,
    hidden: shouldHide(taskInfo),
    disabled: shouldDisable(taskInfo, taskData),
    selected: shouldAutoSelect(taskInfo),
  }));
};