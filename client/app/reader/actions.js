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

export const newTagRequestFailed = () => ({
  type: Constants.REQUEST_NEW_TAG_CREATION_FAILURE
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

export const expandAllPdfCommentList = () => ({
  type: Constants.EXPAND_ALL_PDF_COMMENT_LIST
});

export const collapseAllPdfCommentList = () => ({
  type: Constants.COLLAPSE_ALL_PDF_COMMENT_LIST
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

    // gets the newly added tags
    const newTags = _.differenceWith(tags, currentTags,
      (tag, currentTag) => tag.value === currentTag.text);

    if (newTags && newTags.length) {
      const processedTags = newTags.map((tag) => ({ text: tag.label }));

      dispatch({ type: Constants.REQUEST_NEW_TAG_CREATION });
      ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: processedTags } }).
        then((data) => {
          dispatch(newTagRequestSuccess(doc.id, data.body));
        }, () => {
          dispatch(newTagRequestFailed());
        });
    }
  }
);
