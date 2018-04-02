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

export const wipeLoadedQueue = () => ({
  type: ACTIONS.WIPE_LOADED_QUEUE
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

export const editAppeal = (appealId, attributes) => ({
  type: ACTIONS.EDIT_APPEAL,
  payload: {
    appealId,
    attributes
  }
});

export const startEditingAppeal = (appealId, attributes) => (dispatch) => {
  dispatch({
    type: ACTIONS.START_EDITING_APPEAL,
    payload: {
      appealId
    }
  });

  if (attributes) {
    dispatch(editAppeal(appealId, attributes));
  }
};

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

export const updateEditingAppealIssue = (attributes) => ({
  type: ACTIONS.UPDATE_EDITING_APPEAL_ISSUE,
  payload: {
    attributes
  }
});

export const saveEditedAppealIssue = (appealId) => ({
  type: ACTIONS.SAVE_EDITED_APPEAL_ISSUE,
  payload: {
    appealId
  }
});
