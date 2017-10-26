// closeAnnotationDeleteModal, deleteAnnotation, showPlaceAnnotationIcon,
// selectCurrentPdf, fetchAppealDetails, stopPlacingAnnotation
import _ from 'lodash';
import uuid from 'uuid';

import * as Constants from '../constants';
import { CATEGORIES, ENDPOINT_NAMES } from '../analytics';
import ApiUtil from '../../util/ApiUtil';

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

export const rotateDocument = (docId) => ({
  type: Constants.ROTATE_PDF_DOCUMENT,
  payload: {
    docId
  }
});

// PDF Selection

export const selectCurrentPdfLocally = (docId) => ({
  type: Constants.SELECT_CURRENT_VIEWER_PDF,
  payload: {
    docId
  }
});

export const selectCurrentPdf = (docId) => (dispatch) => {
  ApiUtil.patch(`/document/${docId}/mark-as-read`, {}, ENDPOINT_NAMES.MARK_DOC_AS_READ).
    catch((err) => {
      // eslint-disable-next-line no-console
      console.log('Error marking as read', docId, err);
    });

  dispatch(
    selectCurrentPdfLocally(docId)
  );
};

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

// Accordions

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


export const updateNewAnnotationContent = (content) => ({
  type: Constants.UPDATE_NEW_ANNOTATION_CONTENT,
  payload: {
    content
  }
});

export const createAnnotation = (annotation) => (dispatch) => {
  const temporaryId = uuid.v4();

  dispatch({
    type: Constants.REQUEST_CREATE_ANNOTATION,
    payload: {
      annotation: {
        ...annotation,
        id: temporaryId
      }
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.post(`/document/${annotation.documentId}/annotation`, { data }, ENDPOINT_NAMES.ANNOTATION).
    then(
      (response) => {
        const responseObject = JSON.parse(response.text);

        dispatch({
          type: Constants.REQUEST_CREATE_ANNOTATION_SUCCESS,
          payload: {
            annotation: {
              ...annotation,
              ...responseObject
            },
            annotationTemporaryId: temporaryId
          }
        });
      },
      () => dispatch({
        type: Constants.REQUEST_CREATE_ANNOTATION_FAILURE,
        payload: {
          annotationTemporaryId: temporaryId
        }
      })
    );
};

// JUMP TO PAGE

export const jumpToPage = (pageNumber, docId) => ({
  type: Constants.JUMP_TO_PAGE,
  payload: {
    pageNumber,
    docId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'jump-to-page'
    }
  }
});

export const resetJumpToPage = () => ({
  type: Constants.RESET_JUMP_TO_PAGE
});

// SIDEBAR TAGS

export const collectAllTags = (documents) => ({
  type: Constants.COLLECT_ALL_TAGS_FOR_OPTIONS,
  payload: documents
});

export const removeTagRequestFailure = (docId, tagId) => ({
  type: Constants.REQUEST_REMOVE_TAG_FAILURE,
  payload: {
    docId,
    tagId
  }
});

export const removeTagRequestSuccess = (docId, tagId) => (
  (dispatch, getState) => {
    dispatch({
      type: Constants.REQUEST_REMOVE_TAG_SUCCESS,
      payload: {
        docId,
        tagId
      }
    });
    const { documents } = getState().readerReducer;

    dispatch(collectAllTags(documents));
  }
);

export const newTagRequestSuccess = (docId, createdTags) => (
  (dispatch, getState) => {
    dispatch({
      type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
      payload: {
        docId,
        createdTags
      }
    });
    const { documents } = getState().readerReducer;

    dispatch(collectAllTags(documents));
  }
);

export const newTagRequestFailed = (docId, tagsThatWereAttemptedToBeCreated) => ({
  type: Constants.REQUEST_NEW_TAG_CREATION_FAILURE,
  payload: {
    docId,
    tagsThatWereAttemptedToBeCreated
  }
});

export const addNewTag = (doc, tags) => (
  (dispatch) => {
    const currentTags = doc.tags;

    const newTags = _(tags).
      differenceWith(currentTags, (tag, currentTag) => tag.value === currentTag.text).
      map((tag) => ({ text: tag.label })).
      value();

    if (_.size(newTags)) {
      dispatch({
        type: Constants.REQUEST_NEW_TAG_CREATION,
        payload: {
          newTags,
          docId: doc.id
        }
      });
      ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }, ENDPOINT_NAMES.TAG).
        then((data) => {
          dispatch(newTagRequestSuccess(doc.id, data.body.tags));
        }, () => {
          dispatch(newTagRequestFailed(doc.id, newTags));
        });
    }
  }
);

export const removeTag = (doc, tagId) => (
  (dispatch) => {
    dispatch({
      type: Constants.REQUEST_REMOVE_TAG,
      payload: {
        docId: doc.id,
        tagId
      }
    });
    ApiUtil.delete(`/document/${doc.id}/tag/${tagId}`, {}, ENDPOINT_NAMES.TAG).
      then(() => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      }, () => {
        dispatch(removeTagRequestFailure(doc.id, tagId));
      });
  }
);
