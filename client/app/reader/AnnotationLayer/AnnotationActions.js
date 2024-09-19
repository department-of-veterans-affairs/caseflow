import uuid from 'uuid';

import * as Constants from './actionTypes';
import { CATEGORIES, ENDPOINT_NAMES } from '../analytics';
import ApiUtil from '../../util/ApiUtil';
import { hideErrorMessage, showErrorMessage, updateFilteredIdsAndDocs } from '../commonActions';
import { handleErrorWithSafeNavigation } from '../utils';

/** Annotation Modal **/

export const openAnnotationDeleteModal = (annotationId, analyticsLabel) => ({
  type: Constants.OPEN_ANNOTATION_DELETE_MODAL,
  payload: {
    annotationId,
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'open-annotation-delete-modal',
      label: analyticsLabel,
    },
  },
});

export const closeAnnotationDeleteModal = (includeMetrics = true) => ({
  type: Constants.CLOSE_ANNOTATION_DELETE_MODAL,
  meta: includeMetrics
    ? {
        analytics: {
          category: CATEGORIES.VIEW_DOCUMENT_PAGE,
          action: 'close-annotation-delete-modal',
        },
      }
    : null,
});

export const openAnnotationShareModal = (annotationId, analyticsLabel) => ({
  type: Constants.OPEN_ANNOTATION_SHARE_MODAL,
  payload: {
    annotationId,
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'open-annotation-share-modal',
      label: analyticsLabel,
    },
  },
});

export const closeAnnotationShareModal = (includeMetrics = true) => ({
  type: Constants.CLOSE_ANNOTATION_SHARE_MODAL,
  meta: includeMetrics
    ? {
        analytics: {
          category: CATEGORIES.VIEW_DOCUMENT_PAGE,
          action: 'close-annotation-share-modal',
        },
      }
    : null,
});

export const selectAnnotation = (annotationId) => ({
  type: Constants.SELECT_ANNOTATION,
  payload: {
    annotationId,
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'select-annotation',
    },
  },
});

export const startPlacingAnnotation = (interactionType) => ({
  type: Constants.START_PLACING_ANNOTATION,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'start-placing-annotation',
      label: interactionType,
    },
  },
});

export const stopPlacingAnnotation = (interactionType) => (dispatch) => {
  dispatch(hideErrorMessage('annotation'));
  dispatch({
    type: Constants.STOP_PLACING_ANNOTATION,
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'stop-placing-annotation',
        label: interactionType,
      },
    },
  });
};

export const onReceiveAnnotations = (annotations) => (dispatch) => {
  dispatch({
    type: Constants.RECEIVE_ANNOTATIONS,
    payload: { annotations },
  });
  dispatch(updateFilteredIdsAndDocs());
};

export const placeAnnotation = (pageNumber, coordinates, documentId) => {
  return {
    type: Constants.PLACE_ANNOTATION,
    payload: {
      page: pageNumber,
      x: coordinates.xPosition,
      y: coordinates.yPosition,
      documentId,
    },
  };
};

export const showPlaceAnnotationIcon = (pageIndex, pageCoords) => ({
  type: Constants.SHOW_PLACE_ANNOTATION_ICON,
  payload: {
    pageIndex,
    pageCoords,
  },
});

export const deleteAnnotation = (docId, annotationId) => (dispatch) => {
  dispatch(hideErrorMessage('annotation'));
  dispatch(closeAnnotationDeleteModal(false));
  dispatch({
    type: Constants.REQUEST_DELETE_ANNOTATION,
    payload: {
      annotationId,
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'request-delete-annotation',
      },
    },
  });

  ApiUtil.delete(`/document/${docId}/annotation/${annotationId}`, {}, ENDPOINT_NAMES.ANNOTATION).then(
    () => {
      dispatch(hideErrorMessage('annotation'));
      dispatch({
        type: Constants.REQUEST_DELETE_ANNOTATION_SUCCESS,
        payload: {
          annotationId,
        },
      });
    },
    () => {
      dispatch({
        type: Constants.REQUEST_DELETE_ANNOTATION_FAILURE,
        payload: {
          annotationId,
        },
      });
      dispatch(showErrorMessage('annotation'));
    }
  );
};

export const requestMoveAnnotation = (annotation) => (dispatch) => {
  dispatch(hideErrorMessage('annotation'));
  dispatch({
    type: Constants.REQUEST_MOVE_ANNOTATION,
    payload: {
      annotation,
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'request-move-annotation',
      },
    },
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(
    `/document/${annotation.documentId}/annotation/${annotation.id}`,
    { data },
    ENDPOINT_NAMES.ANNOTATION
  ).then(
    () => {
      dispatch(hideErrorMessage('annotation'));
      dispatch({
        type: Constants.REQUEST_MOVE_ANNOTATION_SUCCESS,
        payload: {
          annotationId: annotation.id,
        },
      });
    },
    () => {
      dispatch(showErrorMessage('annotation'));
      dispatch({
        type: Constants.REQUEST_MOVE_ANNOTATION_FAILURE,
        payload: {
          annotationId: annotation.id,
        },
      });
    }
  );
};

export const startEditAnnotation = (annotationId) => ({
  type: Constants.START_EDIT_ANNOTATION,
  payload: {
    annotationId,
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'start-edit-annotation',
    },
  },
});

export const cancelEditAnnotation = (annotationId) => ({
  type: Constants.CANCEL_EDIT_ANNOTATION,
  payload: {
    annotationId,
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'cancel-edit-annotation',
    },
  },
});

export const updateAnnotationContent = (content, annotationId) => ({
  type: Constants.UPDATE_ANNOTATION_CONTENT,
  payload: {
    annotationId,
    content,
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'edit-annotation-content-locally',
      debounceMs: 500,
    },
  },
});

export const updateAnnotationRelevantDate = (relevantDate, annotationId) => ({
  type: Constants.UPDATE_ANNOTATION_RELEVANT_DATE,
  payload: {
    annotationId,
    relevantDate,
  },
});

export const updateNewAnnotationContent = (content) => ({
  type: Constants.UPDATE_NEW_ANNOTATION_CONTENT,
  payload: {
    content,
  },
});

export const updateNewAnnotationRelevantDate = (relevantDate) => ({
  type: Constants.UPDATE_NEW_ANNOTATION_RELEVANT_DATE,
  payload: {
    relevantDate,
  },
});

export const requestEditAnnotation = (annotation) => (dispatch) => {
  // If the user removed all text content in the annotation (or if only whitespace characters remain),
  // ask the user if they're intending to delete it.
  if (!annotation.comment.trim()) {
    dispatch(openAnnotationDeleteModal(annotation.id, 'open-by-deleting-all-annotation-content'));

    return;
  }

  dispatch(hideErrorMessage('annotation'));
  dispatch({
    type: Constants.REQUEST_EDIT_ANNOTATION,
    payload: {
      annotationId: annotation.id,
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: 'request-edit-annotation',
      },
    },
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(
    `/document/${annotation.documentId}/annotation/${annotation.id}`,
    { data },
    ENDPOINT_NAMES.ANNOTATION
  ).then(
    () => {
      dispatch(hideErrorMessage('annotation'));
      dispatch({
        type: Constants.REQUEST_EDIT_ANNOTATION_SUCCESS,
        payload: {
          annotationId: annotation.id,
        },
      });
    },
    (response) => {
      const errors = handleErrorWithSafeNavigation(response);

      dispatch(showErrorMessage('annotation', errors));
      dispatch({
        type: Constants.REQUEST_EDIT_ANNOTATION_FAILURE,
        payload: {
          annotationId: annotation.id,
        },
      });
    }
  );
};

export const createAnnotation = (annotation) => (dispatch) => {
  const temporaryId = uuid.v4();

  dispatch(hideErrorMessage('annotation'));
  dispatch({
    type: Constants.REQUEST_CREATE_ANNOTATION,
    payload: {
      annotation: {
        ...annotation,
        id: temporaryId,
      },
    },
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.post(`/document/${annotation.documentId}/annotation`, { data }, ENDPOINT_NAMES.ANNOTATION).then(
    (response) => {
      dispatch({
        type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
        payload: {
          annotation: {
            ...annotation,
            ...response.body,
          },
          annotationTemporaryId: temporaryId,
        },
      });
    },
    (response) => {
      const errors = handleErrorWithSafeNavigation(response);

      dispatch(showErrorMessage('annotation', errors));
      dispatch({
        type: Constants.REQUEST_CREATE_ANNOTATION_FAILURE,
        payload: {
          annotationTemporaryId: temporaryId,
        },
      });
    }
  );
};
