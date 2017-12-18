import _ from 'lodash';
import { createSearchAction } from 'redux-search';

import * as Constants from '../constants';

export const getDocumentText = (pdfDocument, file) =>
  (dispatch) => {
    const getTextForPage = (index) => {
      return pdfDocument.getPage(index + 1).then((page) => {
        return page.getTextContent();
      });
    };
    const getTextPromises = _.range(pdfDocument.pdfInfo.numPages).map((index) => getTextForPage(index));

    Promise.all(getTextPromises).then((pages) => {
      const textObject = pages.reduce((acc, page, pageIndex) => {
        // PDFJS textObjects have an array of items. Each item has a str.
        // Concatenating all of these gets us to the page text.
        const concatenated = page.items.map((row) => row.str).join(' ');

        return {
          ...acc,
          [`${file}-${pageIndex}`]: {
            id: `${file}-${pageIndex}`,
            file,
            text: concatenated,
            pageIndex
          }
        };
      }, {});

      dispatch({
        type: Constants.GET_DOCUMENT_TEXT,
        payload: {
          textObject
        }
      });
    });
  };

export const updateSearchIndex = (increment) => ({
  type: Constants.UPDATE_SEARCH_INDEX,
  payload: {
    increment
  }
});

export const setSearchIndex = (index) => ({
  type: Constants.SET_SEARCH_INDEX,
  payload: {
    index
  }
});

export const setSearchIndexToHighlight = (index) => ({
  type: Constants.SET_SEARCH_INDEX_TO_HIGHLIGHT,
  payload: {
    index
  }
});

export const updateSearchIndexPage = (index) => ({
  type: Constants.UPDATE_SEARCH_INDEX_PAGE_INDEX,
  payload: {
    index
  }
});

export const updateSearchRelativeIndex = (index) => ({
  type: Constants.UPDATE_SEARCH_RELATIVE_INDEX,
  payload: {
    index
  }
});

export const searchText = (searchTerm) => (dispatch) => {
  dispatch(setSearchIndex(0));
  dispatch(createSearchAction('extractedText')(searchTerm));
};
