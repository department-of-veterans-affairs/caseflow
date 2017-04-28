import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';

export const onReceiveDocs = (documents) => ({
  type: Constants.RECEIVE_DOCUMENTS,
  payload: documents
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

export const newTagRequestSuccess = (docId, createdTags) => ({
  type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
  payload: {
    docId,
    createdTags
  }
});

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

export const unselectPdf = (docId) => ({
  type: Constants.UNSELECT_CURRENT_VIEWER_PDF,
  payload: {
    docId
  }
});

export const removeTagRequestFailure = (docId, tagId) => ({
  type: Constants.REQUEST_REMOVE_TAG_FAILURE,
  payload: {
    docId,
    tagId
  }
});

export const removeTagRequestSuccess = (docId, tagId) => ({
  type: Constants.REQUEST_REMOVE_TAG_SUCCESS,
  payload: {
    docId,
    tagId
  }
});

export const setPdfReadyToShow = (docId) => ({
  type: Constants.SET_PDF_READY_TO_SHOW,
  payload: {
    docId
  }
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
          dispatch(newTagRequestSuccess(doc.id, data.body));
        }, () => {
          dispatch(newTagRequestFailed(doc.id, newTags));
        });
    }
  }
);
