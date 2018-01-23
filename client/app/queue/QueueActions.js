import { ACTIONS } from './constants';
import { CATEGORIES } from './analytics';

export const onReceiveQueue = ({ tasks, appeals }) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    appeals
  }
});

export const showSearchBar = () => ({
  type: ACTIONS.SHOW_SEARCH_BAR,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DECISIONS_PATH,
      action: 'show-search'
    }
  }
});

export const hideSearchBar = () => ({
  type: ACTIONS.HIDE_SEARCH_BAR,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DECISIONS_PATH,
      action: 'hide-search'
    }
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
