import _ from 'lodash';
import { createSearchAction } from 'redux-search';

import * as Constants from '../constants';

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});

/** PDF Page **/

export const setUpPdfPage = (file, pageIndex, page) => ({
  type: Constants.SET_UP_PDF_PAGE,
  payload: {
    file,
    pageIndex,
    page
  }
});

export const clearPdfPage = (file, pageIndex, page) => ({
  type: Constants.CLEAR_PDF_PAGE,
  payload: {
    file,
    pageIndex,
    page
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
