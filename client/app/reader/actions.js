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

export const newTagRequestSuccess = (docId, createdTags) => {
  return {
    type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
    payload: {
      docId,
      createdTags
    }
  };
};

export const newTagRequestFailed = (errorMessage) => {
  return {
    type: Constants.REQUEST_NEW_TAG_CREATION_FAILURE,
    payload: {
      errorMessage
    }
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

export const showNextPdf = () => {
  return {
    type: Constants.SHOW_NEXT_PDF
  };
};

export const showPrevPdf = () => {
  return {
    type: Constants.SHOW_PREV_PDF
  };
};

export const updateShowingDocId = (currentDocId) => {
  return {
    type: Constants.UPDATE_SHOWING_DOC,
    payload: {
      currentDocId
    }
  };
};

export const removeTagRequestFailure = (errorMessage) => {
  return {
    type: Constants.REQUEST_REMOVE_TAG_FAILURE,
    payload: {
      errorMessage
    }
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
    ApiUtil.delete(`/reader/documents/${doc.id}/tags/${tagId}`).
      then((data) => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      }, () => {
        dispatch(removeTagRequestFailure("Unable to save. Please try again."));
      });
  };
};

export const addNewTag = (doc, tags) => {
  return (dispatch) => {
    const currentTags = doc.tags;

    const prepareTagData = (newTags) => {
      return newTags.map((tag) => {
        return { text: tag.label };
      });
    };

    // gets the newly added tags
    const newTags = _.differenceWith(tags, currentTags, (tag, currentTag) => {
      return tag.value === currentTag.text;
    });

    if (newTags && newTags.length > 0) {
      const processedTags = prepareTagData(newTags);

      dispatch({ type: Constants.REQUEST_NEW_TAG_CREATION });
      ApiUtil.post(`/reader/documents/${doc.id}/tags`, { data: { tags: processedTags } }).
        then((data) => {
          dispatch(newTagRequestSuccess(doc.id, data.body.tags));
        }, () => {
          dispatch(newTagRequestFailed("Unable to save. Please try again."));
        });
    }
  };
};
