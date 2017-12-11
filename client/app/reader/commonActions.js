import { updateFilteredDocIds } from './searchFilters';

import {
  HIDE_ERROR_MESSAGE,
  SHOW_ERROR_MESSAGE
} from './constants';

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

export const updateFilteredIds = () => (dispatch, getState) => {
  const filteredResults = updateFilteredDocIds(getState());

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
