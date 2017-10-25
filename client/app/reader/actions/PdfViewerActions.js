// closeAnnotationDeleteModal, deleteAnnotation, showPlaceAnnotationIcon,
// selectCurrentPdf, fetchAppealDetails, stopPlacingAnnotation

import * as Constants from './constants';
import { CATEGORIES, ENDPOINT_NAMES } from './analytics';
import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';

// Annotations

export const deleteAnnotation = (docId, annotationId) =>
  (dispatch) => {
    dispatch({
      type: Constants.REQUEST_DELETE_ANNOTATION,
      payload: {
        annotationId
      },
      meta: {
        analytics: {
          category: CATEGORIES.VIEW_DOCUMENT_PAGE,
          action: 'request-delete-annotation'
        }
      }
    });

    ApiUtil.delete(`/document/${docId}/annotation/${annotationId}`, {}, ENDPOINT_NAMES.ANNOTATION).
      then(
        () => dispatch({
          type: Constants.REQUEST_DELETE_ANNOTATION_SUCCESS,
          payload: {
            annotationId
          }
        }),
        () => dispatch({
          type: Constants.REQUEST_DELETE_ANNOTATION_FAILURE,
          payload: {
            annotationId
          }
        })
      );
  };

export const showPlaceAnnotationIcon = (pageIndex, pageCoords) => ({
  type: Constants.SHOW_PLACE_ANNOTATION_ICON,
  payload: {
    pageIndex,
    pageCoords
  }
});

// Fetching appeals

export const onReceiveAppealDetails = (appeal) => ({
  type: Constants.RECEIVE_APPEAL_DETAILS,
  payload: { appeal }
});

export const onAppealDetailsLoadingFail = (failedToLoad = true) => ({
  type: Constants.RECEIVE_APPEAL_DETAILS_FAILURE,
  payload: { failedToLoad }
});

export const fetchAppealDetails = (vacolsId) => (
  (dispatch) => {
    ApiUtil.get(`/reader/appeal/${vacolsId}?json`, {}, ENDPOINT_NAMES.APPEAL_DETAILS).then((response) => {
      const returnedObject = JSON.parse(response.text);

      dispatch(onReceiveAppealDetails(returnedObject.appeal));
    }, () => dispatch(onAppealDetailsLoadingFail()));
  }
);

export const stopPlacingAnnotation = (interactionType) => ({
  type: Constants.STOP_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'stop-placing-annotation',
      label: interactionType
    }
  }
});

// Modal

export const closeAnnotationDeleteModal = () => ({
  type: Constants.CLOSE_ANNOTATION_DELETE_MODAL,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'close-annotation-delete-modal'
    }
  }
});

// SIDEBAR
//
// updateAnnotationContent, startEditAnnotation, cancelEditAnnotation, requestEditAnnotation,
//  selectAnnotation, setOpenedAccordionSections, togglePdfSidebar

export const updateAnnotationContent = (content, annotationId) => ({
  type: Constants.UPDATE_ANNOTATION_CONTENT,
  payload: {
    annotationId,
    content
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'edit-annotation-content-locally',
      debounceMs: 500
    }
  }
});

export const startEditAnnotation = (annotationId) => ({
  type: Constants.START_EDIT_ANNOTATION,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'start-edit-annotation'
    }
  }
});

export const cancelEditAnnotation = (annotationId) => ({
  type: Constants.CANCEL_EDIT_ANNOTATION,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'cancel-edit-annotation'
    }
  }
});

export const openAnnotationDeleteModal = (annotationId, analyticsLabel) => ({
  type: Constants.OPEN_ANNOTATION_DELETE_MODAL,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'open-annotation-delete-modal',
      label: analyticsLabel
    }
  }
});

export const requestEditAnnotation = (annotation) => (dispatch) => {
  // If the user removed all text content in the annotation, ask them if they're
  // intending to delete it.
  if (!annotation.comment) {
    dispatch(openAnnotationDeleteModal(annotation.id, 'open-by-deleting-all-annotation-content'));

    return;
  }

  dispatch({
    type: Constants.REQUEST_EDIT_ANNOTATION,
    payload: {
      annotationId: annotation.id
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'request-edit-annotation'
      }
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(`/document/${annotation.documentId}/annotation/${annotation.id}`, { data }, ENDPOINT_NAMES.ANNOTATION).
    then(
      () => dispatch({
        type: Constants.REQUEST_EDIT_ANNOTATION_SUCCESS,
        payload: {
          annotationId: annotation.id
        }
      }),
      () => dispatch({
        type: Constants.REQUEST_EDIT_ANNOTATION_FAILURE,
        payload: {
          annotationId: annotation.id
        }
      })
    );
};

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

export const setOpenedAccordionSections = (openedAccordionSections, prevSections) => ({
  type: Constants.SET_OPENED_ACCORDION_SECTIONS,
  payload: {
    openedAccordionSections
  },
  meta: {
    analytics: (triggerEvent) => {
      const addedSectionKeys = _.difference(openedAccordionSections, prevSections);
      const removedSectionKeys = _.difference(prevSections, openedAccordionSections);

      addedSectionKeys.forEach(
        (newKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'opened-accordion-section', newKey)
      );
      removedSectionKeys.forEach(
        (oldKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'closed-accordion-section', oldKey)
      );
    }
  }
});

export const togglePdfSidebar = () => ({
  type: Constants.TOGGLE_PDF_SIDEBAR,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'toggle-pdf-sidebar',
      label: (nextState) => nextState.readerReducer.ui.pdf.hidePdfSidebar ? 'hide' : 'show'
    }
  }
});
