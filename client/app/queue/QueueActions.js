import * as Constants from './actionTypes';
import { CATEGORIES } from './analytics';

export const onReceiveQueue = ({ tasks, appeals }) => ({
  type: Constants.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DECISIONS_PATH,
      action: 'load-decisions'
    }
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
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DECISIONS_PATH,
      action: 'set-search',
      label: searchQuery
    }
  }
});

export const clearSearch = () => ({
  type: Constants.CLEAR_SEARCH,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DECISIONS_PATH,
      action: 'clear-search'
    }
  }
});
