import _ from 'lodash';
import { getUpdatedFilteredResults } from './searchFilters';

import {
  HIDE_ERROR_MESSAGE,
  SHOW_ERROR_MESSAGE,
  UPDATE_FILTERED_RESULTS,
  ASSIGN_DOCUMENTS
} from './constants';

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
  const { annotationLayer, readerReducer } = getState();
  const filteredResults = getUpdatedFilteredResults(_.merge({},
    readerReducer,
    annotationLayer,
  ));

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
