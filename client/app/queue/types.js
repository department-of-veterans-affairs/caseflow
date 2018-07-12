// @flow

export type DeprecatedTask = {
  id: string
};

export type Task = {
  id: string,
  appealId: string,
  attributes: {
    added_by_css_id: string,
    added_by_name: string,
    appeal_id: string,
    assigned_by_first_name: string,
    assigned_by_last_name: string,
    assigned_on: string,
    docket_date: string,
    docket_name: string,
    document_id: string,
    due_on: string,
    task_id: string,
    task_type: string,
    user_id: string,
    work_product: string
  }
};

export type User = {
  id: number,
  station_id: string,
  css_id: string,
  full_name: string,
  email: ?string,
  roles: Array<String>,
  selected_regional_office: ?string,
  display_name: string,
  judge_css_id: string
};
export type LoadedQueueTasks = { [string]: DeprecatedTask };

export type Tasks = { [string]: Task };

export type LoadedQueueAppeals = { [string]: Object };

export type TasksAndAppealsOfAttorney = {
  [string]: {
    state: string,
    data: {tasks: LoadedQueueTasks, appeals: LoadedQueueAppeals},
    error: {status: number, response: Object}
  }
};

export type AttorneysOfJudge = Array<User>;

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

export type AllAttorneys = {
  data?: Array<User>,
  error?: Object
};

export type UserWithId = {
  [number]: ?User
};

export type QueueState = {
  judges: UserWithId,
  tasks: Tasks,
  loadedQueue: {
    appeals: LoadedQueueAppeals,
    tasks: LoadedQueueTasks,
    loadedUserId: number
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
  isTaskAssignedToUserSelected: IsTaskAssignedToUserSelected,
  allAttorneys: AllAttorneys
};

export type State = {
  caseDetail: CaseDetailState,
  caseList: Object,
  caseSelect: Object,
  queue: QueueState,
  ui: UiState
};
