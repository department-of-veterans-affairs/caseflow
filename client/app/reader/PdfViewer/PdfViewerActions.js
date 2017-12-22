import _ from 'lodash';

import * as Constants from './actionTypes';
import ApiUtil from '../../util/ApiUtil';
import { CATEGORIES, ENDPOINT_NAMES } from '../analytics';
import { selectAnnotation } from '../../reader/AnnotationLayer/AnnotationActions';

export const collectAllTags = (documents) => ({
  type: Constants.COLLECT_ALL_TAGS_FOR_OPTIONS,
  payload: documents
});

/** Jump To Page **/

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

/** Scrolling **/

export const setDocScrollPosition = (scrollTop) => ({
  type: Constants.SET_DOC_SCROLL_POSITION,
  payload: {
    scrollTop
  }
});

/** Getting Appeal Details **/

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

export const setLoadedVacolsId = (vacolsId) => ({
  type: Constants.SET_LOADED_APPEAL_ID,
  payload: {
    vacolsId
  }
});

/** Sidebar and Accordion controls **/

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
      label: (nextState) => nextState.pdfViewer.hidePdfSidebar ? 'hide' : 'show'
    }
  }
});

export const toggleSearchBar = () => ({
  type: Constants.TOGGLE_SEARCH_BAR
});

export const showSearchBar = () => ({
  type: Constants.SHOW_SEARCH_BAR
});

export const hideSearchBar = () => ({
  type: Constants.HIDE_SEARCH_BAR
});

export const resetSidebarErrors = () => ({
  type: Constants.RESET_PDF_SIDEBAR_ERRORS
});

export const handleFinishScrollToSidebarComment = () => ({
  type: Constants.SCROLL_TO_SIDEBAR_COMMENT,
  payload: {
    scrollToSidebarComment: null
  }
});
