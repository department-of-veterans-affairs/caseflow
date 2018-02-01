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
