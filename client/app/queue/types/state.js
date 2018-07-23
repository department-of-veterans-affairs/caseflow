// @flow
import type {
  Task,
  Tasks,
  DeprecatedTask,
  User,
  Attorneys,
  LegacyAppeals
} from './models';

export type LoadedQueueTasks = { [string]: ?DeprecatedTask };
export type LoadedQueueAppeals = LegacyAppeals;

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
  selectedAssignee: ?string,
  selectedAssigneeSecondary: ?string,
  userRole: string
};

export type UsersById = { [number]: ?User };

export type IsTaskAssignedToUserSelected = {[string]: ?{[string]: ?boolean}};

export type QueueState = {
  judges: UsersById,
  tasks: Tasks,
  loadedQueue: {
    appeals: LoadedQueueAppeals,
    tasks: LoadedQueueTasks,
    loadedUserId: ?number
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
  attorneys: Attorneys
};

export type State = {
  caseDetail: CaseDetailState,
  caseList: Object,
  caseSelect: Object,
  queue: QueueState,
  ui: UiState
};

type Action = { type: string, payload: Object };

/* eslint-disable no-use-before-define */

export type Dispatch = (action: Action | ThunkAction | PromiseAction) => any;
export type GetState = () => State;
export type ThunkAction = (dispatch: Dispatch, getState: GetState) => any;
export type PromiseAction = Promise<Action>;

/* eslint-enable no-use-before-define */
