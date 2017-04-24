import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';

export const onReceiveDocs = (documents) => {
  return {
    type: Constants.RECEIVE_DOCUMENTS,
    payload: documents
  };
};

export const onScrollToComment = (scrollToComment) => {
  return {
    type: Constants.SCROLL_TO_COMMENT,
    payload: { scrollToComment }
  };
};

export const handleSetLastRead = (docId) => {
  return {
    type: Constants.LAST_READ_DOCUMENT,
    payload: {
      docId
    }
  };
};

export const newTagRequestSuccess = (docId, createdTags) => {
  return {
    type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
    payload: {
      docId,
      createdTags
    }
  };
};

export const newTagRequestFailed = () => {
  return {
    type: Constants.REQUEST_NEW_TAG_CREATION_FAILURE
  };
};

export const selectCurrentPdf = (docId) => {
  return {
    type: Constants.SELECT_CURRENT_VIEWER_PDF,
    payload: {
      docId
    }
  };
};

export const removeTagRequestFailure = () => {
  return {
    type: Constants.REQUEST_REMOVE_TAG_FAILURE
  };
};

export const removeTagRequestSuccess = (docId, tagId) => {
  return {
    type: Constants.REQUEST_REMOVE_TAG_SUCCESS,
    payload: {
      docId,
      tagId
    }
  };
};


export const removeTag = (doc, tagId) => {
  return (dispatch) => {
    dispatch({ type: Constants.REQUEST_REMOVE_TAG });
    ApiUtil.delete(`/document/${doc.id}/tag/${tagId}`).
      then(() => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      }, () => {
        dispatch(removeTagRequestFailure());
      });
  };
};

export const addNewTag = (doc, tags) => {
  return (dispatch) => {
    const currentTags = doc.tags;

    // gets the newly added tags
    const newTags = _.differenceWith(tags, currentTags, (tag, currentTag) => {
      return tag.value === currentTag.text;
    });

    if (newTags && newTags.length) {
      const processedTags = newTags.map((tag) => {
        return { text: tag.label };
      });

      dispatch({ type: Constants.REQUEST_NEW_TAG_CREATION });
      ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: processedTags } }).
        then((data) => {
          dispatch(newTagRequestSuccess(doc.id, data.body));
        }, () => {
          dispatch(newTagRequestFailed());
        });
    }
  };
};
