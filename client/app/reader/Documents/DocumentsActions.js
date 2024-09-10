import { differenceWith, size, map } from 'lodash';
import * as Constants from './actionTypes';
import ApiUtil from '../../util/ApiUtil';
import { hideErrorMessage, showErrorMessage, updateFilteredIdsAndDocs } from '../commonActions';
import { categoryFieldNameOfCategoryName } from '../utils';
import { collectAllTags, setLoadedVacolsId } from '../PdfViewer/PdfViewerActions';
import { handleSetLastRead } from '../DocumentList/DocumentListActions';
import { setViewedAssignment } from '../CaseSelect/CaseSelectActions';
import { CATEGORIES, ENDPOINT_NAMES } from '../analytics';
import uuid from 'uuid';

/** Tags **/

export const newTagRequestSuccess = (docId, createdTags) => (dispatch, getState) => {
  dispatch({
    type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
    payload: {
      docId,
      createdTags,
    },
  });
  const { documents } = getState();

  dispatch(collectAllTags(documents));
};

export const newTagRequestFailed = (docId, tagsThatWereAttemptedToBeCreated) => (dispatch) => {
  dispatch(showErrorMessage('tag'));
  dispatch({
    type: Constants.REQUEST_NEW_TAG_CREATION_FAILURE,
    payload: {
      docId,
      tagsThatWereAttemptedToBeCreated,
    },
  });
};

export const removeTagRequestFailure = (docId, tagId) => (dispatch) => {
  dispatch(showErrorMessage('tag'));
  dispatch({
    type: Constants.REQUEST_REMOVE_TAG_FAILURE,
    payload: {
      docId,
      tagId,
    },
  });
};

export const removeTagRequestSuccess = (docId, tagId) => (dispatch, getState) => {
  dispatch(hideErrorMessage('tag'));
  dispatch({
    type: Constants.REQUEST_REMOVE_TAG_SUCCESS,
    payload: {
      docId,
      tagId,
    },
  });
  const { documents } = getState();

  dispatch(collectAllTags(documents));
};

export const removeTag = (doc, tag) => (dispatch) => {
  const tagId = typeof tag.id === 'number' ? tag.id : tag.tagId;

  dispatch({
    type: Constants.REQUEST_REMOVE_TAG,
    payload: {
      docId: doc.id,
      tagId,
    },
  });

  if (!tag.temporaryId) {
    ApiUtil.delete(`/document/${doc.id}/tag/${tagId}`, {}, ENDPOINT_NAMES.TAG).then(
      () => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      },
      () => {
        dispatch(removeTagRequestFailure(doc.id, tagId));
      }
    );
  }
};

export const addNewTag = (doc, tags) => (dispatch) => {
  const currentTags = doc.tags;

  const newTags = map(differenceWith(tags, currentTags, (tag, currentTag) => tag.value === currentTag.text), (tag) => ({
    text: tag.label,
    id: uuid.v4(),
    temporaryId: true,
  }));

  if (size(newTags)) {
    dispatch(hideErrorMessage('tag'));
    dispatch({
      type: Constants.REQUEST_NEW_TAG_CREATION,
      payload: {
        newTags,
        docId: doc.id,
      },
    });
    ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }, ENDPOINT_NAMES.TAG).then(
      (data) => {
        dispatch(newTagRequestSuccess(doc.id, data.body.tags));
      },
      () => {
        dispatch(newTagRequestFailed(doc.id, newTags));
      }
    );
  }
};

/** Document Description **/
export const saveDocumentDescription = (docId, description) => (dispatch) => {
  ApiUtil.patch(`/document/${docId}`, { data: { description } }).then(
    () =>
      dispatch({
        type: Constants.SAVE_DOCUMENT_DESCRIPTION_SUCCESS,
        payload: {
          docId,
          description,
        },
      }),
    (resp) => {
      dispatch(showErrorMessage('description', resp.message));
    }
  );
};

export const changePendingDocDescription = (docId, description) => (dispatch) => {
  dispatch(hideErrorMessage('description'));
  dispatch({
    type: Constants.CHANGE_PENDING_DOCUMENT_DESCRIPTION,
    payload: {
      docId,
      description,
    },
  });
};

export const resetPendingDocDescription = (docId) => (dispatch) => {
  dispatch(hideErrorMessage('description'));
  dispatch({
    type: Constants.RESET_PENDING_DOCUMENT_DESCRIPTION,
    payload: {
      docId,
    },
  });
};

/** Rotate Pages **/

export const rotateDocument = (docId) => ({
  type: Constants.ROTATE_PDF_DOCUMENT,
  payload: {
    docId,
  },
});

/** Set current PDF **/
export const selectCurrentPdfLocally = (docId) => (dispatch) => {
  dispatch(handleSetLastRead(docId));
  dispatch({
    type: Constants.SELECT_CURRENT_VIEWER_PDF,
    payload: {
      docId,
    },
  });
};

export const closeDocumentUpdatedModal = (docId) => ({
  type: Constants.CLOSE_DOCUMENT_UPDATED_MODAL,
  payload: {
    docId,
  },
});

export const selectCurrentPdf = (docId) => (dispatch) => {
  ApiUtil.patch(`/document/${docId}/mark-as-read`, {}, ENDPOINT_NAMES.MARK_DOC_AS_READ).catch((err) => {
    // eslint-disable-next-line no-console
    console.log('Error marking as read', docId, err);
  });

  dispatch(selectCurrentPdfLocally(docId));
};

export const onReceiveDocs = (documents, vacolsId) => (dispatch) => {
  dispatch({
    type: Constants.RECEIVE_DOCUMENTS,
    payload: {
      documents,
    },
  });
  dispatch(updateFilteredIdsAndDocs());
  dispatch(collectAllTags(documents));
  dispatch(setViewedAssignment(vacolsId));
  dispatch(setLoadedVacolsId(vacolsId));
};

export const toggleDocumentCategoryFail = (docId, categoryKey, categoryValueToRevertTo) => (dispatch) => {
  dispatch(showErrorMessage('category'));
  dispatch({
    type: Constants.TOGGLE_DOCUMENT_CATEGORY_FAIL,
    payload: {
      docId,
      categoryKey,
      categoryValueToRevertTo,
    },
  });
};

export const handleCategoryToggle = (docId, categoryName, toggleState) => (dispatch) => {
  const categoryKey = categoryFieldNameOfCategoryName(categoryName);

  ApiUtil.patch(`/document/${docId}`, { data: { [categoryKey]: toggleState } }, ENDPOINT_NAMES.DOCUMENT).catch(() =>
    dispatch(toggleDocumentCategoryFail(docId, categoryKey, !toggleState))
  );
  dispatch(hideErrorMessage('category'));
  dispatch({
    type: Constants.TOGGLE_DOCUMENT_CATEGORY,
    payload: {
      categoryKey,
      toggleState,
      docId,
    },
    meta: {
      analytics: {
        category: CATEGORIES.VIEW_DOCUMENT_PAGE,
        action: `${toggleState ? 'set' : 'unset'} document category`,
        label: categoryName,
      },
    },
  });
};

export const handleToggleCommentOpened = (docId) => ({
  type: Constants.TOGGLE_COMMENT_LIST,
  payload: {
    docId,
  },
  meta: {
    analytics: {
      category: CATEGORIES.CLAIMS_FOLDER_PAGE,
      action: 'toggle-comment-list',
      label: (nextState) => (nextState.documents[docId].listComments ? 'open' : 'close'),
    },
  },
});
