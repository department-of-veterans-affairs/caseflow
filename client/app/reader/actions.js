/* eslint-disable max-lines */

import * as Constants from './constants';
import _ from 'lodash';
import ApiUtil from '../util/ApiUtil';
import { CATEGORIES, ENDPOINT_NAMES } from './analytics';
import { createSearchAction } from 'redux-search';
import { selectAnnotation } from '../reader/PdfViewer/AnnotationActions';

export const collectAllTags = (documents) => ({
  type: Constants.COLLECT_ALL_TAGS_FOR_OPTIONS,
  payload: documents
});

export const onScrollToComment = (scrollToComment) => ({
  type: Constants.SCROLL_TO_COMMENT,
  payload: { scrollToComment }
});

export const openAnnotationDeleteModal = (annotationId, analyticsLabel) => ({
  type: Constants.OPEN_ANNOTATION_DELETE_MODAL,
  payload: {
    annotationId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'open-annotation-delete-modal',
      label: analyticsLabel
    }
  }
});

export const closeAnnotationDeleteModal = () => ({
  type: Constants.CLOSE_ANNOTATION_DELETE_MODAL,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'close-annotation-delete-modal'
    }
  }
});

export const jumpToPage = (pageNumber, docId) => ({
  type: Constants.JUMP_TO_PAGE,
  payload: {
    pageNumber,
    docId
  },
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'jump-to-page'
    }
  }
});

export const resetJumpToPage = () => ({
  type: Constants.RESET_JUMP_TO_PAGE
});

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

export const newTagRequestSuccess = (docId, createdTags) =>
  (dispatch, getState) => {
    dispatch({
      type: Constants.REQUEST_NEW_TAG_CREATION_SUCCESS,
      payload: {
        docId,
        createdTags
      }
    });
    const { documents } = getState().readerReducer;

    dispatch(collectAllTags(documents));
  }
;

export const newTagRequestFailed = (docId, tagsThatWereAttemptedToBeCreated) => ({
  type: Constants.REQUEST_NEW_TAG_CREATION_FAILURE,
  payload: {
    docId,
    tagsThatWereAttemptedToBeCreated
  }
});

export const selectCurrentPdfLocally = (docId) => ({
  type: Constants.SELECT_CURRENT_VIEWER_PDF,
  payload: {
    docId
  }
});

export const selectCurrentPdf = (docId) => (dispatch) => {
  ApiUtil.patch(`/document/${docId}/mark-as-read`, {}, ENDPOINT_NAMES.MARK_DOC_AS_READ).
    catch((err) => {
      // eslint-disable-next-line no-console
      console.log('Error marking as read', docId, err);
    });

  dispatch(
    selectCurrentPdfLocally(docId)
  );
};

export const removeTagRequestFailure = (docId, tagId) => ({
  type: Constants.REQUEST_REMOVE_TAG_FAILURE,
  payload: {
    docId,
    tagId
  }
});

export const removeTagRequestSuccess = (docId, tagId) =>
  (dispatch, getState) => {
    dispatch({
      type: Constants.REQUEST_REMOVE_TAG_SUCCESS,
      payload: {
        docId,
        tagId
      }
    });
    const { documents } = getState().readerReducer;

    dispatch(collectAllTags(documents));
  };

export const removeTag = (doc, tagId) =>
  (dispatch) => {
    dispatch({
      type: Constants.REQUEST_REMOVE_TAG,
      payload: {
        docId: doc.id,
        tagId
      }
    });
    ApiUtil.delete(`/document/${doc.id}/tag/${tagId}`, {}, ENDPOINT_NAMES.TAG).
      then(() => {
        dispatch(removeTagRequestSuccess(doc.id, tagId));
      }, () => {
        dispatch(removeTagRequestFailure(doc.id, tagId));
      });
  }
;


export const onReceiveAppealDetails = (appeal) => ({
  type: Constants.RECEIVE_APPEAL_DETAILS,
  payload: { appeal }
});

export const onAppealDetailsLoadingFail = (failedToLoad = true) => ({
  type: Constants.RECEIVE_APPEAL_DETAILS_FAILURE,
  payload: { failedToLoad }
});

export const fetchAppealDetails = (vacolsId) =>
  (dispatch) => {
    ApiUtil.get(`/reader/appeal/${vacolsId}?json`, {}, ENDPOINT_NAMES.APPEAL_DETAILS).then((response) => {
      const returnedObject = JSON.parse(response.text);

      dispatch(onReceiveAppealDetails(returnedObject.appeal));
    }, () => dispatch(onAppealDetailsLoadingFail()));
  };

export const addNewTag = (doc, tags) =>
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
      ApiUtil.post(`/document/${doc.id}/tag`, { data: { tags: newTags } }, ENDPOINT_NAMES.TAG).
        then((data) => {
          dispatch(newTagRequestSuccess(doc.id, data.body.tags));
        }, () => {
          dispatch(newTagRequestFailed(doc.id, newTags));
        });
    }
  }
;

export const setOpenedAccordionSections = (openedAccordionSections, prevSections) => ({
  type: Constants.SET_OPENED_ACCORDION_SECTIONS,
  payload: {
    openedAccordionSections
  },
  meta: {
    analytics: (triggerEvent) => {
      const addedSectionKeys = _.difference(openedAccordionSections, prevSections);
      const removedSectionKeys = _.difference(prevSections, openedAccordionSections);

      addedSectionKeys.forEach(
        (newKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'opened-accordion-section', newKey)
      );
      removedSectionKeys.forEach(
        (oldKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'closed-accordion-section', oldKey)
      );
    }
  }
});

export const togglePdfSidebar = () => ({
  type: Constants.TOGGLE_PDF_SIDEBAR,
  meta: {
    analytics: {
      category: CATEGORIES.VIEW_DOCUMENT_PAGE,
      action: 'toggle-pdf-sidebar',
      label: (nextState) => nextState.readerReducer.ui.pdf.hidePdfSidebar ? 'hide' : 'show'
    }
  }
});

export const setUpPdfPage = (file, pageIndex, page) => ({
  type: Constants.SET_UP_PDF_PAGE,
  payload: {
    file,
    pageIndex,
    page
  }
});

export const clearPdfPage = (file, pageIndex, page) => ({
  type: Constants.CLEAR_PDF_PAGE,
  payload: {
    file,
    pageIndex,
    page
  }
});

export const clearPdfDocument = (file, pageIndex, doc) => ({
  type: Constants.CLEAR_PDF_DOCUMENT,
  payload: {
    file,
    pageIndex,
    doc
  }
});

export const setPdfDocument = (file, doc) => ({
  type: Constants.SET_PDF_DOCUMENT,
  payload: {
    file,
    doc
  }
});

export const rotateDocument = (docId) => ({
  type: Constants.ROTATE_PDF_DOCUMENT,
  payload: {
    docId
  }
});

export const getDocumentText = (pdfDocument, file) =>
  (dispatch) => {
    const getTextForPage = (index) => {
      return pdfDocument.getPage(index + 1).then((page) => {
        return page.getTextContent();
      });
    };
    const getTextPromises = _.range(pdfDocument.pdfInfo.numPages).map((index) => getTextForPage(index));

    Promise.all(getTextPromises).then((pages) => {
      const textObject = pages.reduce((acc, page, pageIndex) => {
        // PDFJS textObjects have an array of items. Each item has a str.
        // concatenating all of these gets us to the page text.
        const concatenated = page.items.map((row) => row.str).join(' ');

        return {
          ...acc,
          [`${file}-${pageIndex}`]: {
            id: `${file}-${pageIndex}`,
            file,
            text: concatenated,
            pageIndex
          }
        };
      }, {});

      dispatch({
        type: Constants.GET_DOCUMENT_TEXT,
        payload: {
          textObject
        }
      });
    });
  }
;

export const updateSearchIndex = (increment) => ({
  type: Constants.UPDATE_SEARCH_INDEX,
  payload: {
    increment
  }
});

export const zeroSearchIndex = () => ({
  type: Constants.ZERO_SEARCH_INDEX
});

export const searchText = (searchTerm) => (dispatch) => {
  dispatch(zeroSearchIndex());
  dispatch(createSearchAction('extractedText')(searchTerm));
};
