import { ACTIONS } from './constants';

export const onReceiveQueue = ({ tasks, appeals }) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals
  }
});

export const setSearch = (searchQuery) => ({
  type: ACTIONS.SET_SEARCH,
  payload: {
    searchQuery
  }
});

export const clearSearch = () => ({
  type: ACTIONS.CLEAR_SEARCH
});
