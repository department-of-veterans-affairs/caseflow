import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES, ENDPOINT_NAMES } from '../analytics';
import { categoryFieldNameOfCategoryName } from '../utils';
import { hideErrorMessage, showErrorMessage, updateFilteredIds } from '../commonActions';

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
          const direction = nextState.readerReducer.ui.docFilterCriteria.sort.sortAscending ? 
            'ascending' : 'descending';

          return `${sortBy}-${direction}`;
        }
      }
    }
  });
  dispatch(updateFilteredIds());
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
  dispatch(updateFilteredIds());
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
  dispatch(updateFilteredIds());
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

export const toggleDocumentCategoryFail = (docId, categoryKey, categoryValueToRevertTo) =>
  (dispatch) => {
    dispatch(showErrorMessage('category'));
    dispatch({
      type: Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL,
      payload: {
        docId,
        categoryKey,
        categoryValueToRevertTo
      }
    });
  };

export const handleCategoryToggle = (docId, categoryName, toggleState) => (dispatch) => {
  const categoryKey = categoryFieldNameOfCategoryName(categoryName);

  ApiUtil.patch(
    `/document/${docId}`,
    { data: { [categoryKey]: toggleState } },
    ENDPOINT_NAMES.DOCUMENT
  ).catch(() =>
    dispatch(toggleDocumentCategoryFail(docId, categoryKey, !toggleState))
  );
  dispatch(hideErrorMessage('category'));
  dispatch({
    type: Constants.TOGGLE_DOCUMENT_CATEGORY,
    payload: {
      categoryKey,
      toggleState,
      docId
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: `${toggleState ? 'set' : 'unset'} document category`,
        label: categoryName
      }
    }
  });
};

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
  dispatch(updateFilteredIds());
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
  dispatch(updateFilteredIds());
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
  dispatch(updateFilteredIds());
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
  dispatch(updateFilteredIds());
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
  dispatch(updateFilteredIds());
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

export const handleToggleCommentOpened = (docId) => ({
  type: Constants.TOGGLE_COMMENT_LIST,
  payload: {
    docId
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'toggle-comment-list',
      label: (nextState) => nextState.readerReducer.documents[docId].listComments ? 'open' : 'close'
    }
  }
});
