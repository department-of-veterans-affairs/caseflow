import { ACTIONS } from './constants';
import { ACTIONS as UIACTIONS } from './uiReducer/constants';
import {
  showErrorMessage,
  hideErrorMessage
} from './uiReducer/actions';

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

export const setDecisionOptions = (opts) => (dispatch) => {
  dispatch(hideErrorMessage('decision'));
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

export const requestSaveDecision = () => (dispatch) => {
  dispatch(hideErrorMessage('decision'));
  dispatch({ type: UIACTIONS.REQUEST_SAVE_DECISION });
};

export const saveDecisionSuccess = () => ({
  type: UIACTIONS.SAVE_DECISION_SUCCESS
});

export const saveDecisionFailure = (resp) => (dispatch) => {
  const errors = JSON.parse(resp.response.text).errors;

  dispatch(showErrorMessage('decision', errors[0]));
  dispatch({ type: UIACTIONS.SAVE_DECISION_FAILURE });
};

export const startEditingAppeal = (vacolsId) => ({
  type: ACTIONS.START_EDITING_APPEAL,
  payload: {
    vacolsId
  }
});

export const cancelEditingAppeal = (vacolsId) => ({
  type: ACTIONS.CANCEL_EDITING_APPEAL,
  payload: {
    vacolsId
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
