import * as Constants from './actionTypes';

export const onReceiveQueue = (tasks, appeals) => ({
  type: Constants.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals
  }
});

export const showSearchBar = () => ({
  type: Constants.SHOW_SEARCH_BAR
});

export const hideSearchBar = () => ({
  type: Constants.HIDE_SEARCH_BAR
});

export const setSearch = (searchQuery) => ({
  type: Constants.SET_SEARCH,
  payload: {
    searchQuery
  }
});

export const clearSearch = () => ({
  type: Constants.CLEAR_SEARCH
});
