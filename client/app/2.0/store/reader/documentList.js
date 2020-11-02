// External Dependencies
import querystring from 'querystring';
import { createSlice, createAction, current } from '@reduxjs/toolkit';
import { sortBy, values, some, find, pickBy } from 'lodash';

// Local Dependencies
import { DOCUMENTS_OR_COMMENTS_ENUM } from 'store/constants/reader';
import { formatCategoryName, searchString, categoryContainsWords } from 'utils/reader';
import { loadDocuments, selectCurrentPdfLocally } from 'store/reader/documents';
import { onReceiveAnnotations } from 'store/reader/annotationLayer';
import { addMetaLabel } from 'utils/reader/format';

/**
 * Helper Method to change the Last Read Document
 * @param {Object} state -- The current Redux Store State
 * @param {string} docId -- The ID of the Document to set as the last Read
 */
export const updateLastReadDoc = (state, docId) => {
  state.pdfList.lastReadDocId = docId;
};

/**
 * Helper Method to Parse the Queue Redirect URL from the window
 * @returns {string|null} -- The Parsed Queue Redirect URL
 */
export const getQueueRedirectUrl = () => {
  // Parse the Redirect URL string from the URL bar
  const query = querystring.parse(window.location.search.slice(1));

  // Return either the parsed URL or null
  return query.queue_redirect_url ? decodeURIComponent(query.queue_redirect_url) : null;
};

/**
 * Helper Method to Parse the Task Type from the window
 * @returns {string|null} -- The Parsed Queue Task Type
 */
export const getQueueTaskType = () => {
  // Parse the Task Type string from the URL bar
  const query = querystring.parse(window.location.search.slice(1));

  // Return either the parsed Task Type or null
  return query.queue_task_type ? decodeURIComponent(query.queue_task_type) : null;
};

/**
 * PDF Initial State
 */
export const initialState = {
  queueRedirectUrl: getQueueRedirectUrl(),
  queueTaskType: getQueueTaskType(),
  viewingDocumentsOrComments: DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS,
  searchCategoryHighlights: {},
  filteredDocIds: [],
  docFilterCriteria: {
    sort: {
      sortBy: 'receivedAt',
      sortAscending: true
    },
    category: {},
    tag: {},
    searchQuery: ''
  },
  pdfList: {
    scrollTop: null,
    lastReadDocId: null,
    dropdowns: {
      tag: false,
      category: false
    }
  },
  manifestVbmsFetchedAt: null,
  manifestVvaFetchedAt: null
};

/**
 * Dispatcher to Update the Document list Sort
 */
export const changeSortState = createAction('documentList/changeSortState');

/**
 * Dispatcher to Remove Category Filters
 */
export const clearCategoryFilters = createAction('documentList/clearCategoryFilters');

/**
 * Dispatcher to Set Category Filters
 */
export const setCategoryFilter = createAction('documentList/setCategoryFilter');

/**
 * Dispatcher to Set Tag Filters
 */
export const setTagFilter = createAction('documentList/setTagFilter');

/**
 * Dispatcher to Clear Tag Filters
 */
export const clearTagFilters = createAction('documentList/clearTagFilters');

/**
 * Dispatcher to Set the Document List Search
 */
export const setSearch = createAction('documentList/setSearch');

/**
 * Dispatcher to Clear the Document List Search
 */
export const clearSearch = createAction('documentList/clearSearch');

/**
 * Dispatcher to Clear All Filters
 */
export const clearAllFilters = createAction('documentList/clearAllFilters');

/**
 * Dispatcher to Set the Last Read Document
 */
export const handleSetLastRead = createAction('documentList/handleSetLastRead');

/**
 * Document List Combined Reducer/Action creators
 */
const documentListSlice = createSlice({
  name: 'documentList',
  initialState,
  reducers: {
    [changeSortState]: {
      reducer: (state, action) => {
        state.docFilterCriteria.sort.sortBy = action.payload.sortBy;
        state.docFilterCriteria.sort.sortAscending =
         !state.docFilterCriteria.sort.sortAscending;
      },
      prepare: (sortBy) => addMetaLabel('change-sort-by', { payload: { sortBy } }, (state) => {
        // Set the sort Direction
        const direction = state.docFilterCriteria.sort.sortAscending ?
          'ascending' : 'descending';

        // Return the formatted sort direction
        return `${sortBy}-${direction}`;
      })
    },
    [clearCategoryFilters]: {
      reducer: (state) => {
        state.docFilterCriteria.category = {};
      },
      prepare: () => addMetaLabel('clear-category-filters')
    },
    [setCategoryFilter]: {
      reducer: (state, action) => {
        state.docFilterCriteria.category[action.payload.categoryName] = action.payload.checked;
      },
      prepare: (categoryName, checked) =>
        addMetaLabel(`${checked ? 'select' : 'unselect'}-category-filter`, { categoryName, checked }, categoryName)
    },
    toggleDropdownFilterVisibility: {
      reducer: (state, action) => {
        state.docFilterCriteria.category[action.payload.categoryName] = action.payload.checked;
      },
      prepare: (filterName) => addMetaLabel('toggle-dropdown-filter', { filterName }, filterName)
    },
    [setTagFilter]: {
      reducer: (state, action) => {
        state.docFilterCriteria.tag[action.payload.text] = action.payload.checked;
      },
      prepare: (text, checked, tagId) =>
        addMetaLabel(`${checked ? 'select' : 'unselect'}-category-filter`, { text, checked }, tagId)
    },
    [clearTagFilters]: {
      reducer: (state) => {
        state.docFilterCriteria.tag = {};
      },
      prepare: () => addMetaLabel('clear-tag-filters')
    },
    setDocListScrollPosition: {
      reducer: (state, action) => {
        state.pdfList.scrollTop = action.payload.scrollTop;
      },
      prepare: (scrollTop) => ({ payload: { scrollTop } })
    },
    [setSearch]: {
      reducer: (state, action) => {
        state.docFilterCriteria.searchQuery = action.payload.searchQuery;
      },
      prepare: (searchQuery) => addMetaLabel('clear-tag-filters', { searchQuery })
    },
    [clearSearch]: {
      reducer: (state) => {
        state.docFilterCriteria.searchQuery = '';
      },
      prepare: () => addMetaLabel('clear-search')
    },
    [clearAllFilters]: {
      reducer: (state) => {
        state.docFilterCriteria.tag = {};
        state.docFilterCriteria.category = {};
        state.viewingDocumentsOrComments = DOCUMENTS_OR_COMMENTS_ENUM.DOCUMENTS;
      },
      prepare: () => addMetaLabel('clear-all-filters')
    },
    setViewingDocumentsOrComments: {
      reducer: (state, action) => {
        state.viewingDocumentsOrComments = action.payload.documentsOrComments;
      },
      prepare: (documentsOrComments) =>
        addMetaLabel('set-viewing-documents-or-comments', { documentsOrComments }, documentsOrComments)
    },
    onReceiveManifests: {
      reducer: (state, action) => {
        state.manifestVbmsFetchedAt = action.payload.manifestVbmsFetchedAt;
        state.manifestVvaFetchedAt = action.payload.manifestVvaFetchedAt;
      },
      prepare: (manifestVbmsFetchedAt, manifestVvaFetchedAt) =>
        ({ payload: { manifestVbmsFetchedAt, manifestVvaFetchedAt } })
    },
  },
  extraReducers: (builder) => {
    builder.
      addMatcher(
        (action) => [
          selectCurrentPdfLocally.toString()
        ].includes(action.type),
        (state, action) => {
          updateLastReadDoc(state, action.payload.docId);
        }
      ).
      addMatcher(
        (action) => [
          onReceiveAnnotations.toString(),
          changeSortState.toString(),
          clearCategoryFilters.toString(),
          setCategoryFilter.toString(),
          setTagFilter.toString(),
          clearTagFilters.toString(),
          setSearch.toString(),
          clearSearch.toString(),
          clearAllFilters.toString(),
          loadDocuments.fulfilled.toString()
        ].includes(action.type),
        (state, action) => {
          // If the Action is loading the documents, also update the manifest
          if (action.type === loadDocuments.fulfilled.toString()) {
            state.manifestVbmsFetchedAt = action.payload.manifestVbmsFetchedAt;
            state.manifestVvaFetchedAt = action.payload.manifestVvaFetchedAt;
          }

          // Set the Documents
          const documents = action.payload.appealDocuments;

          // Extract the Filter Criteria to process
          const { docFilterCriteria } = state;

          // Get the currently selected category filters
          const activeCategoryFilters = values(docFilterCriteria.category).map((key) => formatCategoryName(key));

          // Get the currently selected tag filters
          const activeTagFilters = values(docFilterCriteria.tag).map((key) => formatCategoryName(key));

          // Format the search query
          const searchQuery = docFilterCriteria.searchQuery.toLowerCase();

          // Set the Filtered IDs
          const filteredIds = sortBy(Object.keys(documents).
            filter((doc) =>
              !activeCategoryFilters.length ||
              some(activeCategoryFilters, (categoryFieldName) => documents[doc][categoryFieldName])).
            filter((doc) =>
              !activeTagFilters.length ||
              some(activeTagFilters, (tagText) => find(documents[doc].tags, { text: tagText }))).
            filter(searchString(searchQuery, state)), docFilterCriteria.sort.sortBy).
            map((doc) => documents[doc].id);

          // Check whether there is a search query to locate
          if (searchQuery) {
          // Loop through all the documents to update category highlights and expanding comments
            Object.keys(documents).forEach((id) => {
            // Set the document
              const doc = documents[id];

              // Getting all the truthy values from the object
              const matchesCategories = pickBy(categoryContainsWords(searchQuery, doc));

              // Update the state for all the search category highlights
              if (matchesCategories !== state.searchCategoryHighlights[doc.id]) {
                state.searchCategoryHighlights[doc.id] = matchesCategories;
              }
            });
          }

          // Reverse the order of the filteredIds if we are sorting ascending
          if (docFilterCriteria.sort.sortAscending) {
            filteredIds.reverse();
          }

          // Set the Filtered IDs
          state.filteredDocIds = filteredIds;
        });
  }
});

// Export the Reducer actions
export const {
  toggleDropdownFilterVisibility,
  setDocListScrollPosition,
  setViewingDocumentsOrComments,
  onReceiveManifests
} = documentListSlice.actions;

// Default export the reducer
export default documentListSlice.reducer;

