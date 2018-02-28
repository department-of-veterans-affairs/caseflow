import { ACTIONS } from './constants';

export const onReceiveQueue = ({ tasks, appeals, userId }) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals,
    userId
  }
});

export const onReceiveJudges = (judges) => ({
  type: ACTIONS.RECEIVE_JUDGE_DETAILS,
  payload: {
    judges
  }
});

export const setAppealDocCount = ({ vacolsId, docCount }) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    vacolsId,
    docCount
  }
});

export const loadAppealDocCountFail = (vacolsId) => ({
  type: ACTIONS.LOAD_APPEAL_DOC_COUNT_FAILURE,
  payload: {
    vacolsId,
    docCount: null
  }
});

export const setCaseReviewActionType = (type) => ({
  type: ACTIONS.SET_REVIEW_ACTION_TYPE,
  payload: {
    type
  }
});

export const setDecisionOptions = (opts) => ({
  type: ACTIONS.SET_DECISION_OPTIONS,
  payload: {
    opts
  }
});

export const startEditingAppeal = (vacolsId) => ({
  type: ACTIONS.START_EDITING_OBJECT,
  payload: {
    type: 'appeals',
    vacolsId
  }
});

export const startEditingTask = (vacolsId) => ({
  type: ACTIONS.START_EDITING_OBJECT,
  payload: {
    type: 'tasks',
    vacolsId
  }
});

export const cancelEditingAppeal = (vacolsId) => ({
  type: ACTIONS.CANCEL_EDITING_OBJECT,
  payload: {
    type: 'appeals',
    vacolsId
  }
});

export const cancelEditingTask = (vacolsId) => ({
  type: ACTIONS.CANCEL_EDITING_OBJECT,
  payload: {
    type: 'tasks',
    vacolsId
  }
});

export const updateAppeal = (vacolsId, attributes) => ({
  type: ACTIONS.UPDATE_OBJECT,
  payload: {
    type: 'appeals',
    vacolsId,
    attributes
  }
});

export const updateAppealIssue = (appealId, issueId, attributes) => ({
  type: ACTIONS.UPDATE_APPEAL_ISSUE,
  payload: {
    appealId,
    issueId,
    attributes
  }
});

export const updateTask = (vacolsId, attributes) => ({
  type: ACTIONS.UPDATE_OBJECT,
  payload: {
  type: 'tasks',
  vacolsId,
  attributes
});

export const setSelectingJudge = (selectingJudge) => ({
  type: ACTIONS.SET_SELECTING_JUDGE,
  payload: {
    selectingJudge
  }
});
