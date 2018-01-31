import { ACTIONS } from './constants';

export const setLoadedQueueId = (userId) => ({
  type: ACTIONS.SET_LOADED_QUEUE_ID,
  payload: {
    userId
  }
});

export const onReceiveQueue = ({ tasks, appeals, userId }) => (dispatch) => {
  dispatch({
    type: ACTIONS.RECEIVE_QUEUE_DETAILS,
    payload: {
      tasks,
      appeals
    }
  });
  dispatch(setLoadedQueueId(userId))
};

export const setAppealDocCount = ({ appealId, docCount }) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    appealId,
    docCount
  }
});
