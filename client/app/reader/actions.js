import * as Constants from './constants';
import ApiUtil from '../util/ApiUtil';

export const onReceiveDocs = (documents) => {
  return {
    type: Constants.RECEIVE_DOCUMENTS,
    payload: documents
  };
}

export const updatedTagList = (docId, createdTags) => {
  return {
    type: Constants.UPDATE_DOCUMENT_TAG_LIST,
    payload: {
      docId: docId,
      createdTags: createdTags
    }
  };
}

export const tagSaveFailed = (errorMessage) => {
  return {
    type: Constants.SHOW_TAG_SAVE_ERROR_MESSAGE,
    payload: {
      errorMessage: errorMessage
    }
  };
}

export const selectCurrentPdf = (docId) => {
  return {
    type: Contants.SELECT_CURRENT_VIEWER_PDF,
    payload: {
      docId: docId
    }
  }
}

export const addNewTag = (doc, tags) => {
  return(dispatch) => {
    const currentTags = doc.tags;

    const prepareTagData = (newTags) => {
      return newTags.map((tag) => {
        return { text: tag.label };
      });
    };

    // gets the newly added tags
    const newTags = _.differenceWith(tags, currentTags, (tag, currentTag) => {
      return tag.value === currentTag.text
    });

    if(newTags && newTags.length > 0) {
      const processedTags = prepareTagData(newTags);
      dispatch({ type: Constants.REQUEST_NEW_TAG_CREATION })
      ApiUtil.post(`/reader/documents/${doc.id}/tags`, { data: {tags: processedTags} }).
        then((data) => {
          dispatch(updatedTagList(doc.id, data.body.tags));
        }, () => {
          /* eslint-disable no-console */
          dispatch(tagSaveFailed("Unable to save. Please try again!"));
          /* eslint-enable no-console */
        });
    }
  }
}
