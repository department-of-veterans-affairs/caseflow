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

export const editAppeal = (appealId, attributes) => ({
  type: ACTIONS.EDIT_APPEAL,
  payload: {
    appealId,
    attributes
  }
});

export const deleteAppeal = (appealId) => ({
  type: ACTIONS.DELETE_APPEAL,
  payload: {
    appealId
  }
});

export const editStagedAppeal = (appealId, attributes) => ({
  type: ACTIONS.EDIT_STAGED_APPEAL,
  payload: {
    appealId,
    attributes
  }
});

export const stageAppeal = (appealId, attributes) => (dispatch) => {
  dispatch({
    type: ACTIONS.STAGE_APPEAL,
    payload: {
      appealId
    }
  });

  if (attributes) {
    dispatch(editStagedAppeal(appealId, attributes));
  }
};

export const checkoutStagedAppeal = (appealId) => ({
  type: ACTIONS.CHECKOUT_STAGED_APPEAL,
  payload: {
    appealId
  }
});

export const updateEditingAppealIssue = (attributes) => ({
  type: ACTIONS.UPDATE_EDITING_APPEAL_ISSUE,
  payload: {
    attributes
  }
});

export const startEditingAppealIssue = (appealId, issueId, attributes) => (dispatch) => {
  dispatch({
    type: ACTIONS.START_EDITING_APPEAL_ISSUE,
    payload: {
      appealId,
      issueId
    }
  });

  if (attributes) {
    dispatch(updateEditingAppealIssue(attributes));
  }
};

export const deleteEditingAppealIssue = (appealId, issueId, attributes) => (dispatch) => {
  dispatch({
    type: ACTIONS.DELETE_EDITING_APPEAL_ISSUE,
    payload: {
      appealId,
      issueId
    }
  });
  dispatch(editAppeal(appealId, attributes));
};

export const cancelEditingAppealIssue = () => ({
  type: ACTIONS.CANCEL_EDITING_APPEAL_ISSUE
});

export const saveEditedAppealIssue = (appealId, attributes) => (dispatch) => {
  dispatch({
    type: ACTIONS.SAVE_EDITED_APPEAL_ISSUE,
    payload: {
      appealId
    }
  });

  if (attributes) {
    dispatch(editStagedAppeal(appealId, attributes));
    dispatch(editAppeal(appealId, attributes));
  }
};

export const setAttorneysOfJudge = (attorneys) => ({
  type: ACTIONS.SET_ATTORNEYS_OF_JUDGE,
  payload: {
    attorneys
  }
});

export const setTasksAndAppealsOfAttorney = ({attorneyId, tasks, appeals}) => ({
  type: ACTIONS.SET_TASKS_AND_APPEALS_OF_ATTORNEY,
  payload: {
    attorneyId,
    tasks,
    appeals
  }
});
