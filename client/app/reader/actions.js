import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';
import uuid from 'uuid';

export const collectAllTags = (documents) => ({
  type: Constants.COLLECT_ALL_TAGS_FOR_OPTIONS,
  payload: documents
});

export const onReceiveDocs = (documents) => (
  (dispatch) => {
    dispatch(collectAllTags(documents));
    dispatch({
      type: Constants.RECEIVE_DOCUMENTS,
      payload: documents
    });
  }
);

export const onReceiveAnnotations = (annotations) => ({
  type: Constants.RECEIVE_ANNOTATIONS,
  payload: { annotations }
});

export const toggleDocumentCategoryFail = (docId, categoryKey, categoryValueToRevertTo) => ({
  type: Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL,
  payload: {
    docId,
    categoryKey,
    categoryValueToRevertTo
  }
});

export const toggleExpandAll = () => ({
  type: Constants.TOGGLE_EXPAND_ALL
});

export const setSearch = (searchQuery) => ({
  type: Constants.SET_SEARCH,
  payload: {
    searchQuery
  }
});

export const setDocListScrollPosition = (scrollTop) => ({
  type: Constants.SET_DOC_LIST_SCROLL_POSITION,
  payload: {
    scrollTop
  }
});

export const changeSortState = (sortBy) => ({
  type: Constants.SET_SORT,
  payload: {
    sortBy
  }
});

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});

export const startEditAnnotation = (annotationId) => ({
  type: Constants.START_EDIT_ANNOTATION,
  payload: {
    annotationId
  }
});

export const openAnnotationDeleteModal = (annotationId) => ({
  type: Constants.OPEN_ANNOTATION_DELETE_MODAL,
  payload: {
    annotationId
  }
});
export const closeAnnotationDeleteModal = () => ({ type: Constants.CLOSE_ANNOTATION_DELETE_MODAL });
export const selectAnnotation = (annotationId) => ({
  type: Constants.SELECT_ANNOTATION,
  payload: {
    annotationId
  }
});

export const deleteAnnotation = (docId, annotationId) =>
  (dispatch) => {
    dispatch({
      type: Constants.REQUEST_DELETE_ANNOTATION,
      payload: {
        annotationId
      }
    });

    ApiUtil.delete(`/document/${docId}/annotation/${annotationId}`).
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

export const requestMoveAnnotation = (annotation) => (dispatch) => {
  dispatch({
    type: Constants.REQUEST_MOVE_ANNOTATION,
    payload: {
      annotation
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(`/document/${annotation.documentId}/annotation/${annotation.id}`, { data }).
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

export const cancelEditAnnotation = (annotationId) => ({
  type: Constants.CANCEL_EDIT_ANNOTATION,
  payload: {
    annotationId
  }
});
export const updateAnnotationContent = (content, annotationId) => ({
  type: Constants.UPDATE_ANNOTATION_CONTENT,
  payload: {
    annotationId,
    content
  }
});
export const updateNewAnnotationContent = (content) => ({
  type: Constants.UPDATE_NEW_ANNOTATION_CONTENT,
  payload: {
    content
  }
});

export const requestEditAnnotation = (annotation) => (dispatch) => {
  // If the user removed all text content in the annotation, ask them if they're
  // intending to delete it.
  if (!annotation.comment) {
    dispatch(openAnnotationDeleteModal(annotation.id));

    return;
  }

  dispatch({
    type: Constants.REQUEST_EDIT_ANNOTATION,
    payload: {
      annotationId: annotation.id
    }
  });

  const data = ApiUtil.convertToSnakeCase({ annotation });

  ApiUtil.patch(`/document/${annotation.documentId}/annotation/${annotation.id}`, { data }).
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

export const startPlacingAnnotation = () => ({ type: Constants.START_PLACING_ANNOTATION });

export const placeAnnotation = (pageNumber, coordinates, documentId) => ({
  type: Constants.PLACE_ANNOTATION,
  payload: {
    page: pageNumber,
    x: coordinates.xPosition,
    y: coordinates.yPosition,
    documentId
  }
});

export const stopPlacingAnnotation = () => ({ type: Constants.STOP_PLACING_ANNOTATION });

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

  ApiUtil.post(`/document/${annotation.documentId}/annotation`, { data }).
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

export const handleSetLastRead = (docId) => ({
  type: Constants.LAST_READ_DOCUMENT,
  payload: {
    docId
  }
});

export const newTagRequestSuccess = (docId, createdTags) => (
  (dispatch, getState) => {
    dispatch({
      type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
      payload: {
        docId,
        createdTags
      }
    });
    const { documents } = getState();

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

export const selectCurrentPdf = (docId) => (dispatch) => {
  ApiUtil.patch(`/document/${docId}/mark-as-read`).
    catch((err) => {
      // eslint-disable-next-line no-console
      console.log('Error marking as read', docId, err);
    });

  dispatch({
    type: Constants.SELECT_CURRENT_VIEWER_PDF,
    payload: {
      docId
    }
  });
};

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
    const { documents } = getState();

    dispatch(collectAllTags(documents));
  }
);

export const setPdfReadyToShow = (docId) => ({
  type: Constants.SET_PDF_READY_TO_SHOW,
  payload: {
    docId
  }
});

export const setTagFilter = (text, checked) => ({
  type: Constants.SET_TAG_FILTER,
  payload: {
    text,
    checked
  }
});

export const setCategoryFilter = (categoryName, checked) => ({
  type: Constants.SET_CATEGORY_FILTER,
  payload: {
    categoryName,
    checked
  }
});

export const clearAllFilters = () => ({
  type: Constants.CLEAR_ALL_FILTERS
});

export const clearSearch = () => ({
  type: Constants.CLEAR_ALL_SEARCH
});

export const removeTag = (doc, tagId) => (
  (dispatch) => {
    dispatch({
      type: Constants.REQUEST_REMOVE_TAG,
      payload: {
        docId: doc.id,
        tagId
      }
    });
    ApiUtil.delete(`/document/${doc.id}/tag/${tagId}`).
      then(() => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      }, () => {
        dispatch(removeTagRequestFailure(doc.id, tagId));
      });
  }
);

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
      ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }).
        then((data) => {
          dispatch(newTagRequestSuccess(doc.id, data.body.tags));
        }, () => {
          dispatch(newTagRequestFailed(doc.id, newTags));
        });
    }
  }
);
