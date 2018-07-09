// @flow
import type {
  Task,
  Tasks,
  DeprecatedTask
} from './models';

export type LoadedQueueTasks = { [string]: DeprecatedTask };

export type LoadedQueueAppeals = { [string]: Object };

export type TasksAndAppealsOfAttorney = {
  [string]: {
    state: string,
    data: {tasks: LoadedQueueTasks, appeals: LoadedQueueAppeals},
    error: {status: number, response: Object}
  }
};

export type AttorneysOfJudge = Array<Object>;

export type CaseDetailState = {|
  activeAppeal: ?Object,
  activeTask: ?Task
|};

export type UiStateError = {title: string, detail: string}

export type UiState = {
  selectingJudge: boolean,
  breadcrumbs: Array<Object>,
  highlightFormItems: boolean,
  messages: {
    success: ?string,
    error: ?UiStateError
  },
  saveState: {
    savePending: boolean,
    saveSuccessful: ?boolean
  },
  modal: {
    cancelCheckout: boolean,
    deleteIssue: boolean
  },
  featureToggles: Object,
  selectedAssignee: ?string
};

export type IsTaskAssignedToUserSelected = {[string]: ?{[string]: ?boolean}};

export type QueueState = {
  judges: Object,
  tasks: Tasks,
  loadedQueue: {
    appeals: LoadedQueueAppeals,
    tasks: LoadedQueueTasks,
    loadedUserId: string
  },
  editingIssue: Object,
  docCountForAppeal: {[string]: Object},
  stagedChanges: {
    appeals: {[string]: Object},
    taskDecision: {
      type: string,
      opts: Object
    }
  },
  attorneysOfJudge: AttorneysOfJudge,
  tasksAndAppealsOfAttorney: TasksAndAppealsOfAttorney,
  isTaskAssignedToUserSelected: IsTaskAssignedToUserSelected
};

export type State = {
  caseDetail: CaseDetailState,
  caseList: Object,
  caseSelect: Object,
  queue: QueueState,
  ui: UiState
};
