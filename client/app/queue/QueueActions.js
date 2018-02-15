import { ACTIONS } from './constants';

export const onReceiveQueue = ({ tasks, appeals, userId }) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals,
    userId
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

export const setDecisionType = (type) => ({
  type: ACTIONS.SET_DECISION_TYPE,
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
