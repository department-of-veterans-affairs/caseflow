import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';

export const onReceiveDocs = (documents) => {
  return {
    type: Constants.RECEIVE_DOCUMENTS,
    payload: documents
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

export const removeTag = (doc, deletedTag) => {
  return (dispatch) => {
    if (deletedTag) {
      console.log(deletedTag)
      dispatch({ type: Constants.REQUEST_REMOVE_TAG });
      ApiUtil.delete(`/reader/documents/${doc.id}/tags/${deletedTag[0].tagId}`).
        then((data) => {
          console.log(data);
          //dispatch(newTagRequestSuccess(doc.id, data.body.tags));
        }, () => {
          console.log("failed");
          dispatch();
        });
    }
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
