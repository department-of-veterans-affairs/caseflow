// @flow
import * as React from 'react';
import type {
  Task,
  Tasks,
  Appeals,
  BasicAppeals,
  AppealDetails,
  User,
  Attorneys
} from './models';

export type AttorneyAppealsLoadingState = {
  [string]: {
    state: string,
    data: {tasks: Tasks, appeals: Appeals},
    error: {status: number, response: Object}
  }
};

export type AttorneysOfJudge = Array<User>;

export type CaseDetailState = {|
  activeAppeal: ?Object,
  activeTask: ?Task
|};

export type UiStateModals = {|
  deleteIssue?: boolean,
  cancelCheckout?: boolean,
  sendToAttorney?: boolean,
  sendToTeam?: boolean
|};

export type UiStateMessage = { title: string, detail?: React.Node };

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
  modals: UiStateModals,
  featureToggles: Object,
  selectedAssignee: ?string,
  selectedAssigneeSecondary: ?string,
  loadedUserId: ?number,
  userRole: string,
  userCssId: string,
  userIsVsoEmployee: boolean,
  feedbackUrl: string,
  veteranCaseListIsVisible: boolean,
  organizationIds: Array<number>,
  canEditAod: Boolean
};

export type UsersById = { [number]: ?User };

export type IsTaskAssignedToUserSelected = {[string]: ?{[string]: ?boolean}};

export type NewDocsForAppeal = {[string]: {docs?: Array<Object>, error?: Object, loading: boolean}}

export type QueueState = {|
  judges: UsersById,
  tasks: Tasks,
  appeals: BasicAppeals,
  appealDetails: AppealDetails,
  amaTasks: Tasks,
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
  attorneys: Attorneys,
  newDocsForAppeal: NewDocsForAppeal,
  organizationId: ?number,
  specialIssues: Object,
  loadingAppealDetail: Object
|};

export type CommonComponentState = {|
  regionalOffices: Array<Object>,
  selectedRegionalOffice: { label: string, value: string },
|};

export type State = {
  caseDetail: CaseDetailState,
  caseList: Object,
  caseSelect: Object,
  queue: QueueState,
  ui: UiState,
  components: CommonComponentState
};

type Action = { type: string, payload?: Object };

/* eslint-disable no-use-before-define */

export type Dispatch = (action: Action | ThunkAction | PromiseAction) => any;
export type GetState = () => State;
export type ThunkAction = (dispatch: Dispatch, getState: GetState) => any;
export type PromiseAction = Promise<Action>;

/* eslint-enable no-use-before-define */
