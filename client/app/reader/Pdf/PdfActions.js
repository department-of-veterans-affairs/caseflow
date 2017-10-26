// placeAnnotation, startPlacingAnnotation,
// stopPlacingAnnotation, showPlaceAnnotationIcon,
// onScrollToComment

import { createSearchAction } from 'redux-search';

import * as Constants from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES } from '../analytics';

export const placeAnnotation = (pageNumber, coordinates, documentId) => ({
  type: Constants.PLACE_ANNOTATION,
  payload: {
    page: pageNumber,
    x: coordinates.xPosition,
    y: coordinates.yPosition,
    documentId
  }
});

export const startPlacingAnnotation = (interactionType) => ({
  type: Constants.START_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'startplacing-annotation',
      label: interactionType
    }
  }
});

export const stopPlacingAnnotation = (interactionType) => ({
  type: Constants.STOP_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'stopplacingannotation',
      label: interactionType
    }
  }
});

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});

export const selectAnnotation = (annotationId) => ({
  type: Constants.SELECT_ANNOTATION,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'select-annotation'
    }
  }
});

export const handleSelectCommentIcon = (comment) => (dispatch) => {
  // Normally, we would not want to fire two actions here.
  // I think that SCROLL_TO_SIDEBAR_COMMENT needs cleanup
  // more generally, so I'm just going to leave it alone for now,
  // and hack this in here.
  dispatch(selectAnnotation(comment.id));
  dispatch({
    type: Constants.SCROLL_TO_SIDEBAR_COMMENT,
    payload: {
      scrollToSidebarComment: comment
    }
  });
};

export const requestMoveAnnotation = (annotation) => (dispatch) => {
  dispatch({
    type: Constants.REQUEST_MOVE_ANNOTATION,
    payload: {
      annotation
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'request-move-annotation'
      }
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(`/document/${annotation.documentId}/annotation/${annotation.id}`, { data }, ENDPOINT_NAMES.ANNOTATION).
    then(
      () => dispatch({
        type: Constants.REQUEST_MOVE_ANNOTATION_SUCCESS,
        payload: {
          annotationId: annotation.id
        }
      }),
      () => dispatch({
        type: Constants.REQUEST_MOVE_ANNOTATION_FAILURE,
        payload: {
          annotationId: annotation.id
        }
      })
    );
};

export const rotateDocument = (docId) => ({
  type: Constants.ROTATE_PDF_DOCUMENT,
  payload: {
    docId
  }
});

// PDF PAGE actions

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

// PDF FILE ACTIONS

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


// Document Search

export const getDocumentText = (pdfDocument, file) => (
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
);


export const searchText = createSearchAction('extractedText');
