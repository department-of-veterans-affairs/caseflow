import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES, ENDPOINT_NAMES } from '../analytics';
import { categoryFieldNameOfCategoryName } from '../utils';

// Table header actions

export const changeSortState = (sortBy) => ({
  type: Constants.SET_SORT,
  payload: {
    sortBy
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'change-sort-by',
      label: (nextState) => {
        const direction = nextState.readerReducer.ui.docFilterCriteria.sort.sortAscending ? 'ascending' : 'descending';

        return `${sortBy}-${direction}`;
      }
    }
  }
});

/* Filters */

// Category filters

export const clearCategoryFilters = () => ({
  type: Constants.CLEAR_CATEGORY_FILTER,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-category-filters'
    }
  }
});

export const setCategoryFilter = (categoryName, checked) => ({
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

export const toggleDocumentCategoryFail = (docId, categoryKey, categoryValueToRevertTo) => ({
  type: Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL,
  payload: {
    docId,
    categoryKey,
    categoryValueToRevertTo
  }
});

export const handleCategoryToggle = (docId, categoryName, toggleState) => (dispatch) => {
  const categoryKey = categoryFieldNameOfCategoryName(categoryName);

  ApiUtil.patch(
    `/document/${docId}`,
    { data: { [categoryKey]: toggleState } },
    ENDPOINT_NAMES.DOCUMENT
  ).catch(() =>
    dispatch(toggleDocumentCategoryFail(docId, categoryKey, !toggleState))
  );

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

export const setTagFilter = (text, checked, tagId) => ({
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

export const clearTagFilters = () => ({
  type: Constants.CLEAR_TAG_FILTER,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-tag-filters'
    }
  }
});

// Scrolling

export const setDocListScrollPosition = (scrollTop) => ({
  type: Constants.SET_DOC_LIST_SCROLL_POSITION,
  payload: {
    scrollTop
  }
});

// Document header

export const setSearch = (searchQuery) => ({
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

export const clearSearch = () => ({
  type: Constants.CLEAR_ALL_SEARCH,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-search'
    }
  }
});

export const clearAllFilters = () => ({
  type: Constants.CLEAR_ALL_FILTERS,
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'clear-all-filters'
    }
  }
});

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
