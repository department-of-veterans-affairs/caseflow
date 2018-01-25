import { ACTIONS } from './constants';

export const onReceiveQueue = ({ tasks, appeals }) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals
  }
});

export const setAppealDocCount = ({ appealId, docCount }) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    appealId,
    docCount
  }
});
