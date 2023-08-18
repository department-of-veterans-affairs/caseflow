import * as Constants from './actionTypes';
import { CATEGORIES } from '../analytics';
import { updateFilteredIdsAndDocs } from '../commonActions';

export const handleSetLastRead = (docId) => ({
  type: Constants.LAST_READ_DOCUMENT,
  payload: {
    docId
  }
});

// Table header actions

export const changeSortState = (sortBy) => (dispatch) => {
  dispatch({
    type: Constants.SET_SORT,
    payload: {
      sortBy
    },
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: 'change-sort-by',
        label: (nextState) => {
          const direction = nextState.documentList.docFilterCriteria.sort.sortAscending ?
            'ascending' : 'descending';

          return `${sortBy}-${direction}`;
        }
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

/* Filters */

// Category filters

export const clearCategoryFilters = () => (dispatch) => {
  dispatch({
    type: Constants.CLEAR_CATEGORY_FILTER,
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: 'clear-category-filters'
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

export const setCategoryFilter = (categoryName, checked) => (dispatch) => {
  dispatch({
    type: Constants.SET_CATEGORY_FILTER,
    payload: {
      categoryName,
      checked
    },
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: `${checked ? 'select' : 'unselect'}-category-filter`,
        label: categoryName
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

export const toggleDropdownFilterVisibility = (filterName) => ({
  type: Constants.TOGGLE_FILTER_DROPDOWN,
  payload: {
    filterName
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'toggle-dropdown-filter',
      label: filterName
    }
  }
});

// Tag filters

export const setTagFilter = (text, checked, tagId) => (dispatch) => {
  dispatch({
    type: Constants.SET_TAG_FILTER,
    payload: {
      text,
      checked
    },
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: `${checked ? 'set' : 'unset'}-tag-filter`,
        label: tagId
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

export const setDocFilter = (text, checked, tagId) => ({
  type: Constants.SET_DOC_FILTER,
  payload: { text, checked, tagId }
});

export const clearDocFilters = () => (dispatch) => {
  dispatch({
    type: Constants.CLEAR_DOC_FILTER,
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: 'clear-doc-filters'
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

export const clearTagFilters = () => (dispatch) => {
  dispatch({
    type: Constants.CLEAR_TAG_FILTER,
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: 'clear-tag-filters'
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

// Scrolling

export const setDocListScrollPosition = (scrollTop) => ({
  type: Constants.SET_DOC_LIST_SCROLL_POSITION,
  payload: {
    scrollTop
  }
});

// Document header

export const setSearch = (searchQuery) => (dispatch) => {
  dispatch({
    type: Constants.SET_SEARCH,
    payload: {
      searchQuery
    },
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: 'search',
        debounceMs: 500
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

export const clearSearch = () => (dispatch) => {
  dispatch({
    type: Constants.CLEAR_ALL_SEARCH,
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: 'clear-search'
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};

export const clearAllFilters = () => (dispatch) => {
  dispatch({
    type: Constants.CLEAR_ALL_FILTERS,
    meta: {
      analytics: {
        category: CATEGORIES.CLAIMS_FOLDER_PAGE,
        action: 'clear-all-filters'
      }
    }
  });
  dispatch(updateFilteredIdsAndDocs());
};
export const setViewingDocumentsOrComments = (documentsOrComments) => ({
  type: Constants.SET_VIEWING_DOCUMENTS_OR_COMMENTS,
  payload: {
    documentsOrComments
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'set-viewing-documents-or-comments',
      label: documentsOrComments
    }
  }
});

export const onReceiveManifests = (manifestVbmsFetchedAt, manifestVvaFetchedAt) => ({
  type: Constants.RECEIVE_MANIFESTS,
  payload: { manifestVbmsFetchedAt,
    manifestVvaFetchedAt }
});

