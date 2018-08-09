// @flow
import type {
  LegacyTask,
  LegacyTasks,
  AmaTasks,
  LegacyAppeals,
  BasicAppeals,
  User,
  Attorneys
} from './models';

export type AttorneyAppealsLoadingState = {
  [string]: {
    state: string,
    data: {tasks: LegacyTasks, appeals: LegacyAppeals},
    error: {status: number, response: Object}
  }
};

export type AttorneysOfJudge = Array<User>;

export type CaseDetailState = {|
  activeAppeal: ?Object,
  activeTask: ?LegacyTask
|};

export type UiStateMessage = { title: string, detail?: string };

export type UiState = {
  selectingJudge: boolean,
  highlightFormItems: boolean,
  messages: {
    success: ?UiStateMessage,
    error: ?UiStateMessage
  },
  saveState: {
    savePending: boolean,
    saveSuccessful: ?boolean
  },
  modal: Object,
  featureToggles: Object,
  selectedAssignee: ?string,
  selectedAssigneeSecondary: ?string,
  loadedUserId: ?number,
  userRole: string,
  userCssId: string,
  veteranCaseListIsVisible: boolean
};

export type UsersById = { [number]: ?User };

export type IsTaskAssignedToUserSelected = {[string]: ?{[string]: ?boolean}};

export type QueueState = {
  judges: UsersById,
  tasks: LegacyTasks,
  appeals: BasicAppeals,
  appealDetails: LegacyAppeals,
  amaTasks: AmaTasks,
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
  attorneyAppealsLoadingState: AttorneyAppealsLoadingState,
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

type Action = { type: string, payload?: Object };

/* eslint-disable no-use-before-define */

export type Dispatch = (action: Action | ThunkAction | PromiseAction) => any;
export type GetState = () => State;
export type ThunkAction = (dispatch: Dispatch, getState: GetState) => any;
export type PromiseAction = Promise<Action>;

/* eslint-enable no-use-before-define */
