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

export const mailTasks = [
  'AddressChangeMailTask',
  'AodMotionMailTask',
  'AppealWithdrawalMailTask',
  'CavcCorrespondenceMailTask',
  'ClearAndUnmistakeableErrorMailTask',
  'CongressionalInterestMailTask',
  'ControlledCorrespondenceMailTask',
  'DeathCertificateMailTask',
  'DocketSwitchMailTask',
  'EvidenceOrArgumentMailTask',
  'ExtensionRequestMailTask',
  'FoiaRequestMailTask',
  'HearingRelatedMailTask',
  'OtherMotionMailTask',
  'PowerOfAttorneyRelatedMailTask',
  'PrivacyActRequestMailTask',
  'PrivacyComplaintMailTask',
  'ReconsiderationMotionMailTask',
  'ReturnedUndeliverableCorrespondenceMailTask',
  'StatusInquiryMailTask',
  'VacateMotionMailTask',
];

export const hearingAdminActions = [
  'HearingAdminActionContestedClaimantTask',
  'HearingAdminActionFoiaPrivacyRequestTask',
  'HearingAdminActionForeignVeteranCaseTask',
  'HearingAdminActionIncarceratedVeteranTask',
  'HearingAdminActionMissingFormsTask',
  'HearingAdminActionOtherTask',
  'HearingAdminActionVerifyAddressTask',
  'HearingAdminActionVerifyPoaTask',
];

export const nonAutomatedTasksToHide = [
  'RootTask',
  'AssignHearingDispositionTask',
  'ChangeHearingDispositionTask',
];

export const CavcAppealTaskTypes = [
  'SendCavcRemandProcessedLetterTask',
  'CavcRemandProcessedLetterResponseWindowTask',
  'MdrTask',
  'IhpColocatedTask',
  'FoiaRequestMailTask',
  'FoiaTask',
  'FoiaColocatedTask',
]

export const closedTasksToHide = [...automatedTasks, ...nonAutomatedTasksToHide, ...mailTasks, ...hearingAdminActions];
// This may be refined after user testing...
export const openTasksToHide = [...nonAutomatedTasksToHide, ...automatedTasks];

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
      'EvidenceSubmissionWindowTask',
      'TranscriptionTask',
    ],
    EvidenceSubmissionWindowTask: [
      'ScheduleHearingTask',
    ],
    TranscriptionTask: [
      'ScheduleHearingTask',
    ],
  };

  return Object.entries(disablingTaskMap).some(([selectionType, toDisable]) => {
    return selectedTaskTypes.includes(selectionType) && toDisable.includes(taskType);
  });
};

// The following governs what should always be programmatically disabled from selection
export const alwaysDisabled = ['DistributionTask'];

export const shouldDisable = (taskInfo) => {
  return CavcAppealTaskTypes.includes(taskInfo.type);
};

export const disabledTasksBasedOnSelections = ({ tasks, selectedTaskIds }) => {
  const selectedTaskTypes = taskTypesSelected({ tasks, selectedTaskIds });

  return tasks.map((task) => {
    return ({
      ...task,
      disabled: true
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
  // Some tasks should always be hidden, regardless of additional context
  if (closedTasksToHide.includes(taskInfo.type)) {
    return true;
  }

  // eslint-disable-next-line max-len
  return (taskInfo.hideFromCaseTimeline || shouldHideBasedOnPoa(taskInfo, claimantPoa)) && !shouldShowBasedOnOtherTasks(taskInfo, allTasks);
};

export const shouldAutoSelect = (taskInfo) => {
  return !(CavcAppealTaskTypes.includes(taskInfo.type));
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

// This returns array of tasks with relevant booleans for hidden/disabled
export const prepTaskDataForUi = ({ taskData, claimantPoa, isSubstitutionSameAppeal }) => {
  const uniqTasks = filterTasks(taskData);

  const sortedTasks = sortTasks(uniqTasks);

  const filteredBySubstitutionType = isSubstitutionSameAppeal ?
    sortedTasks.filter((task) => task.type !== 'DistributionTask') :
    sortedTasks;

  return filteredBySubstitutionType.map((taskInfo) => ({
    ...taskInfo,
    hidden: shouldHide(taskInfo, claimantPoa, taskData),
    disabled: shouldDisable(taskInfo),
    selected: shouldAutoSelect(taskInfo),
  }));
};

export const filterOpenTasks = (tasks) => tasks.filter((task) => {
  return ['assigned', 'on_hold'].includes(task.status);
});

export const filterCancelOrCompletedTasks = (tasks) => tasks.filter((task) => {
  return ['completed', 'cancelled'].includes(task.status);
});

export const shouldHideOpen = (taskInfo, claimantPoa, allTasks) => {
  // Some tasks should always be hidden, regardless of additional context
  if (openTasksToHide.includes(taskInfo.type)) {
    return true;
  }

  // eslint-disable-next-line max-len
  return (taskInfo.hideFromCaseTimeline || shouldHideBasedOnPoa(taskInfo, claimantPoa)) && !shouldShowBasedOnOtherTasks(taskInfo, allTasks);
};

// For open tasks, we want to prevent (de)selection of child tasks if parent tasks have been selected to be cancelled
export const adjustOpenTasksBasedOnSelection = ({ tasks, selectedTaskIds }) => {
  const deselectedTaskIds = tasks.
    filter((task) => !selectedTaskIds.includes(Number(task.taskId))).
    map((task) => Number(task.taskId));

  return tasks.map((task) => ({
    ...task,
    disabled:
      task.disabled,
    selected: task.selected,
  }));
};

export const editCavcRemandSubstitutionOpenTaskDataForUi = ({ taskData }) => {
  const activeTasks = filterOpenTasks(taskData);
  const uniqTasks = filterTasks(activeTasks, { orgOnly: false, closedOnly: false });

  const sortedTasks = sortTasks(uniqTasks, 'createdAt');
  return sortedTasks.map((taskInfo) => ({
    ...taskInfo,
    disabled: shouldDisable(taskInfo),
    selected: shouldAutoSelect(taskInfo),
  }));
};

export const editCavcRemandSubstitutionCancelOrCompletedTaskDataForUi = ({ taskData }) => {
  const inActiveTasks = filterCancelOrCompletedTasks(taskData);
  const uniqTasks = filterTasks(inActiveTasks);

  const sortedTasks = sortTasks(uniqTasks, 'closedAt');

  const filteredBySubstitutionType = sortedTasks.filter((task) => ["SendCavcRemandProcessedLetterTask"].includes(task.type))

  return filteredBySubstitutionType.map((taskInfo) => ({
    ...taskInfo,
    disabled: true,
    selected: true,
  }));
};
