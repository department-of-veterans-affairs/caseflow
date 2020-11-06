// External Dependencies
import querystring from 'querystring';
import { createSlice, createAction } from '@reduxjs/toolkit';
import { pickBy } from 'lodash';

// Local Dependencies
import { DOCUMENTS_OR_COMMENTS_ENUM } from 'store/constants/reader';
import { categoryContainsWords } from 'utils/reader';
import { loadDocuments, selectCurrentPdfLocally } from 'store/reader/documents';
import { onReceiveAnnotations } from 'store/reader/annotationLayer';
import { addMetaLabel } from 'utils/reader/format';
import { filterDocuments } from 'utils/reader/documents';

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
  filterCriteria: {
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
    dropdown: {
      tag: false,
      category: false
    }
  },
  manifestVbmsFetchedAt: null,
  manifestVvaFetchedAt: null
};

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
    changeSortState: {
      reducer: (state, action) => {
        state.filterCriteria.sort.sortBy = action.payload.sortBy;
        state.filterCriteria.sort.sortAscending =
         !state.filterCriteria.sort.sortAscending;
      },
      prepare: (sortBy, props) => addMetaLabel('change-sort-by', { sortBy, ...props },
        `${sortBy}-${props.filterCriteria.sort.sortAscending ? 'ascending' : 'descending'}`
      )
    },
    clearCategoryFilters: {
      reducer: (state) => {
        state.filterCriteria.category = {};
      },
      prepare: (props) => addMetaLabel('clear-category-filters', { ...props })
    },
    setCategoryFilter: {
      reducer: (state, action) => {
        state.filterCriteria.category[action.payload.categoryName] = action.payload.checked;
      },
      prepare: (categoryName, checked, props) =>
        addMetaLabel(`${checked ? 'select' : 'unselect'}-category-filter`, { categoryName, checked, ...props }, categoryName)
    },
    toggleDropdownFilterVisibility: {
      reducer: (state, action) => {
        state.pdfList.dropdown[action.payload.filterName] = !state.pdfList.dropdown[action.payload.filterName];
      },
      prepare: (filterName) => addMetaLabel('toggle-dropdown-filter', { filterName }, filterName)
    },
    setTagFilter: {
      reducer: (state, action) => {
        state.filterCriteria.tag[action.payload.text] = action.payload.checked;
      },
      prepare: (text, checked, tagId, props) =>
        addMetaLabel(`${checked ? 'select' : 'unselect'}-category-filter`, { ...props, text, checked }, tagId)
    },
    clearTagFilters: {
      reducer: (state) => {
        state.filterCriteria.tag = {};
      },
      prepare: (props) => addMetaLabel('clear-tag-filters', { ...props })
    },
    setDocListScrollPosition: {
      reducer: (state, action) => {
        state.pdfList.scrollTop = action.payload.scrollTop;
      },
      prepare: (scrollTop) => ({ payload: { scrollTop } })
    },
    setSearch: {
      reducer: (state, action) => {
        state.filterCriteria.searchQuery = action.payload.filterCriteria.searchQuery;
      },
      prepare: (searchQuery, annotations, documents) =>
        addMetaLabel('clear-tag-filters', { filterCriteria: { searchQuery }, annotations, documents })
    },
    clearSearch: {
      reducer: (state) => {
        state.filterCriteria.searchQuery = '';
      },
      prepare: (filterCriteria, annotations, documents) =>
        addMetaLabel('clear-search', { filterCriteria, annotations, documents })
    },
    clearAllFilters: {
      reducer: (state) => {
        state.filterCriteria = initialState.filterCriteria;
      },
      prepare: (props) => addMetaLabel('clear-all-filters', { ...props })
    },
    setViewingDocumentsOrComments: {
      reducer: (state, action) => {
        state.viewingDocumentsOrComments = action.payload.documentsView;
      },
      prepare: (documentsView) =>
        addMetaLabel('set-viewing-documents-or-comments', { documentsView }, documentsView)
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
          'documentList/setSearch',
          'documentList/clearSearch',
          'documentList/changeSortState',
          'documentList/setCategoryFilter',
          'documentList/clearCategoryFilters',
          'documentList/clearAllFilters',
          'documentList/setTagFilter',
          'documentList/clearTagFilters',
          onReceiveAnnotations.toString(),
          loadDocuments.fulfilled.toString(),
        ].includes(action.type),
        (state, action) => {
          // If the Action is loading the documents, also update the manifest
          if (action.type === loadDocuments.fulfilled.toString()) {
            state.manifestVbmsFetchedAt = action.payload.manifestVbmsFetchedAt;
            state.manifestVvaFetchedAt = action.payload.manifestVvaFetchedAt;
          }

          // Set the Documents
          const documents = action.payload.documents;

          // Extract the Filter Criteria to process
          const { filterCriteria } = state;

          // Format the search query
          const searchQuery = filterCriteria.searchQuery.toLowerCase();

          // Set the Filtered IDs
          state.filteredDocIds = filterDocuments(filterCriteria, documents, action.payload);

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
        });
  }
});

// Export the Reducer actions
export const {
  toggleDropdownFilterVisibility,
  setDocListScrollPosition,
  setViewingDocumentsOrComments,
  onReceiveManifests,
  setSearch,
  clearSearch,
  changeSortState,
  setCategoryFilter,
  clearCategoryFilters,
  clearAllFilters,
  setTagFilter,
  clearTagFilters
} = documentListSlice.actions;

// Default export the reducer
export default documentListSlice.reducer;

