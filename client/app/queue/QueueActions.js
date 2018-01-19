import * as Constants from './actionTypes';

export const onReceiveQueue = ({ tasks, appeals }) => ({
  type: Constants.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals
  }
});
