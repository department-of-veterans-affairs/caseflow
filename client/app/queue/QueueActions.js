import { ACTIONS } from './constants';
import { hideErrorMessage } from './uiReducer/uiActions';

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

export const setAppealDocCount = (appealId, docCount) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    appealId,
    docCount
  }
});

export const loadAppealDocCountFail = (appealId) => ({
  type: ACTIONS.LOAD_APPEAL_DOC_COUNT_FAILURE,
  payload: {
    appealId,
    docCount: null
  }
});

export const setCaseReviewActionType = (type) => ({
  type: ACTIONS.SET_REVIEW_ACTION_TYPE,
  payload: {
    type
  }
});

export const setDecisionOptions = (opts) => (dispatch) => {
  dispatch(hideErrorMessage());
  dispatch({
    type: ACTIONS.SET_DECISION_OPTIONS,
    payload: {
      opts
    }
  });
};

export const resetDecisionOptions = () => ({
  type: ACTIONS.RESET_DECISION_OPTIONS
});

export const startEditingAppeal = (appealId) => ({
  type: ACTIONS.START_EDITING_APPEAL,
  payload: {
    appealId
  }
});

export const cancelEditingAppeal = (appealId) => ({
  type: ACTIONS.CANCEL_EDITING_APPEAL,
  payload: {
    appealId
  }
});

export const startEditingAppealIssue = (appealId, issueId) => ({
  type: ACTIONS.START_EDITING_APPEAL_ISSUE,
  payload: {
    appealId,
    issueId
  }
});

export const cancelEditingAppealIssue = () => ({
  type: ACTIONS.CANCEL_EDITING_APPEAL_ISSUE
});

export const updateAppealIssue = (appealId, issueId, attributes) => ({
  type: ACTIONS.UPDATE_APPEAL_ISSUE,
  payload: {
    appealId,
    issueId,
    attributes
  }
});

export const saveEditedAppealIssue = (appealId, issueId) => ({
  type: ACTIONS.SAVE_EDITED_APPEAL_ISSUE,
  payload: {
    appealId,
    issueId
  }
});
