import * as Constants from './actionTypes';

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
