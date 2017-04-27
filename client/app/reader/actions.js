import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';

export const onReceiveDocs = (documents) => ({
  type: Constants.RECEIVE_DOCUMENTS,
  payload: documents
});

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
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

export const selectCurrentPdf = (docId) => ({
  type: Constants.SELECT_CURRENT_VIEWER_PDF,
  payload: {
    docId
  }
});

export const removeTagRequestFailure = () => ({
  type: Constants.REQUEST_REMOVE_TAG_FAILURE
});

export const toggleExpandAll = () => ({
  type: Constants.TOGGLE_EXPAND_ALL
});

export const removeTagRequestSuccess = (docId, tagId) => ({
  type: Constants.REQUEST_REMOVE_TAG_SUCCESS,
  payload: {
    docId,
    tagId
  }
});

export const removeTag = (doc, tagId) => (
  (dispatch) => {
    dispatch({ type: Constants.REQUEST_REMOVE_TAG });
    ApiUtil.delete(`/document/${doc.id}/tag/${tagId}`).
      then(() => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      }, () => {
        dispatch(removeTagRequestFailure());
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
