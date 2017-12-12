import _ from 'lodash';
import { createSearchAction } from 'redux-search';

import * as Constants from '../constants';

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});

/** PDF Page **/

export const setPageDimensions = (file, pageIndex, dimensions) => ({
  type: Constants.SET_UP_PAGE_DIMENSIONS,
  payload: {
    file,
    pageIndex,
    dimensions
  }
});

/** PDF file Actions **/

export const setPdfDocument = (file, doc) => ({
  type: Constants.SET_PDF_DOCUMENT,
  payload: {
    file,
    doc
  }
});

export const clearPdfDocument = (file, pageIndex, doc) => ({
  type: Constants.CLEAR_PDF_DOCUMENT,
  payload: {
    file,
    pageIndex,
    doc
  }
});

export const setDocumentLoadError = (file) => ({
  type: Constants.SET_DOCUMENT_LOAD_ERROR,
  payload: { file }
});

export const clearDocumentLoadError = (file) => ({
  type: Constants.CLEAR_DOCUMENT_LOAD_ERROR,
  payload: { file }
});

/** Document Search **/

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
        // concatenating all of these gets us to the page text.
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
  }
;

export const updateSearchIndex = (increment) => ({
  type: Constants.UPDATE_SEARCH_INDEX,
  payload: {
    increment
  }
});

export const zeroSearchIndex = () => ({
  type: Constants.ZERO_SEARCH_INDEX
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

export const searchText = (searchTerm) => (dispatch) => {
  dispatch(zeroSearchIndex());
  dispatch(createSearchAction('extractedText')(searchTerm));
};

/** Rotate Pages **/

export const rotateDocument = (docId) => ({
  type: Constants.ROTATE_PDF_DOCUMENT,
  payload: {
    docId
  }
});
