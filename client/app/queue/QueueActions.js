import { ACTIONS } from './constants';
import { CATEGORIES } from './analytics';

export const onReceiveQueue = ({ tasks, appeals }) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
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
  type: ACTIONS.SHOW_SEARCH_BAR
});

export const hideSearchBar = () => ({
  type: ACTIONS.HIDE_SEARCH_BAR
});

export const setSearch = (searchQuery) => ({
  type: ACTIONS.SET_SEARCH,
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
  type: ACTIONS.CLEAR_SEARCH,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DECISIONS_PATH,
      action: 'clear-search'
    }
  }
});
