import { getUpdatedFilteredResults } from './searchFilters';

import {
  HIDE_ERROR_MESSAGE,
  SHOW_ERROR_MESSAGE
} from './PdfViewer/actionTypes';

import { UPDATE_FILTERED_RESULTS } from './DocumentList/actionTypes';
import { ASSIGN_DOCUMENTS } from './Documents/actionTypes';

// errors

export const hideErrorMessage = (messageType) => ({
  type: HIDE_ERROR_MESSAGE,
  payload: {
    messageType
  }
});

export const showErrorMessage = (messageType, errorMessage) => ({
  type: SHOW_ERROR_MESSAGE,
  payload: {
    messageType,
    errorMessage
  }
});

// Apply filters

export const updateFilteredIdsAndDocs = () => (dispatch, getState) => {
  const filteredResults = getUpdatedFilteredResults(getState());

  dispatch({
    type: ASSIGN_DOCUMENTS,
    payload: {
      documents: filteredResults.documents
    }
  });

  dispatch({
    type: UPDATE_FILTERED_RESULTS,
    payload: {
      searchCategoryHighlights: filteredResults.searchCategoryHighlights,
      filteredIds: filteredResults.filteredIds
    }
  });
};
