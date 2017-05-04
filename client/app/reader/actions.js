import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';

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

export const onReceiveAnnotations = (annotations) => (
  (dispatch) => {
    dispatch({
      type: Constants.RECEIVE_ANNOTATIONS,
      payload: { annotations }
    });
  }
);

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

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});

export const handlePlaceComment = () => ({
  type: Constants.SET_COMMENT_FLOW_STATE,
  payload: {
    state: Constants.PLACING_COMMENT_STATE
  }
});

export const handleWriteComment = () => ({
  type: Constants.SET_COMMENT_FLOW_STATE,
  payload: {
    state: Constants.WRITING_COMMENT_STATE
  }
});

export const handleClearCommentState = () => ({
  type: Constants.SET_COMMENT_FLOW_STATE,
  payload: {
    state: null
  }
});

export const handleSelectCommentIcon = (comment) => ({
  type: Constants.SCROLL_TO_SIDEBAR_COMMENT,
  payload: {
    scrollToSidebarComment: comment
  }
});

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

export const clearAllFilters = () => ({
  type: Constants.CLEAR_ALL_FILTERS
});

export const clearSearch = () => ({
  type: Constants.CLEAR_ALL_SEARCH
});

export const openAnnotationDeleteModal = () => (dispatch) => dispatch({type: Constants.OPEN_ANNOTATION_DELETE_MODAL})

export const deleteAnnotation = (docId, annotationId) => 
  (dispatch) => {
    ApiUtil.delete(`/document/${docId}/annotation/${annotationId}`);
    dispatch({
      type: Constants.REQUEST_DELETE_ANNOTATION,
      payload: {
        docId,
        annotationId
      }
    });
  };

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
          dispatch(newTagRequestSuccess(doc.id, data.body));
        }, () => {
          dispatch(newTagRequestFailed(doc.id, newTags));
        });
    }
  }
);
