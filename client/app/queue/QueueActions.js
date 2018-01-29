import { ACTIONS } from './constants';

export const onReceiveQueue = ({ tasks, appeals }) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals
  }
});
