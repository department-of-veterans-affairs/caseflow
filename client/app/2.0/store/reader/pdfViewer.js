import { createSlice, createAction, createAsyncThunk } from '@reduxjs/toolkit';
import { random, uniqWith, isEqual, difference } from 'lodash';
import { CATEGORIES, ENDPOINT_NAMES, COMMENT_ACCORDION_KEY } from 'store/constants/reader';
import { deleteAnnotation, moveAnnotation, editAnnotation, stopPlacingAnnotation } from 'store/reader/annotationLayer';
import { addMetaLabel } from 'utils/reader/format';
import ApiUtil from 'app/util/ApiUtil';
import {
  loadDocuments,
  removeTag,
  addTag,
  saveDocumentDescription,
  changePendingDocDescription,
  resetPendingDocDescription,
  toggleDocumentCategoryFail,
  handleCategoryToggle
} from 'store/reader/documents';

/**
 * PDF SideBar Error State
 */
const initialPdfSidebarErrorState = {
  tag: { visible: false, message: null },
  category: { visible: false, message: null },
  annotation: { visible: false, message: null },
  description: { visible: false, message: null }
};

/**
 * PDF Initial State
 */
export const initialState = {
  loadedAppealId: null,
  loadedAppeal: {},
  openedAccordionSections: ['Categories', 'Issue tags', COMMENT_ACCORDION_KEY],
  tagOptions: [],
  hidePdfSidebar: false,
  jumpToPageNumber: null,
  scrollTop: 0,
  hideSearchBar: true,
  pdfSideBarError: initialPdfSidebarErrorState,
  didLoadAppealFail: false,
  scrollToSidebarComment: null,
  scale: 1,
  windowingOverscan: random(5, 10)
};

/**
 * Helper Method to update the PDF SideBar Error state
 * @param {Object} state -- The current Redux State
 * @param {string} errorType -- The type of error being set in the SideBar
 * @param {boolean} isVisible -- Whether the error should be visible
 * @param {string} errorMsg -- An optional error message
 */
export const setErrorMessageState = (state, errorType, isVisible, errorMsg = null) => {
  state.pdfSideBarError[errorType] = {
    visible: isVisible,
    message: isVisible ? errorMsg : null
  };
};

/**
 * Appeal Details State
 */
export const fetchAppealDetails = createAsyncThunk('pdfViewer/fetchAppeal', async (vacolsId) => {
  // Request the Appeal
  const { body } = await ApiUtil.get(`/reader/appeal/${vacolsId}?json`, {}, ENDPOINT_NAMES.APPEAL_DETAILS);

  // Return the Body containing the appeal details
  return body;
});

/**
 * Dispatcher for collecting all tags
 */
export const collectAllTags = createAction('pdfViewer/collectAllTags');

/**
 * PDF Combined Reducer/Action creators
 */
const pdfViewerSlice = createSlice({
  name: 'pdfViewer',
  initialState,
  reducers: {
    jumpToPage: {
      reducer: (state, action) => {
        state.jumpToPageNumber = action.payload.pageNumber;
      },
      prepare: (pageNumber, docId) => addMetaLabel('jump-to-page', { pageNumber, docId })
    },
    resetJumpToPage: (state) => {
      state.jumpToPageNumber = null;
    },
    handleSelectCommentIcon: {
      reducer: (state, action) => {
        state.scrollToSidebarComment = action.payload.scrollToSidebarComment;
      },
      prepare: (comment) => ({ payload: { scrollToSidebarComment: comment } })
    },
    setDocScrollPosition: {
      reducer: (state, action) => {
        state.scrollTop = action.payload.scrollTop;
      },
      prepare: (scrollTop) => ({ payload: { scrollTop } })
    },
    setLoadedVacolsId: {
      reducer: (state, action) => {
        state.loadedAppealId = action.payload.vacolsId;
      },
      prepare: (vacolsId) => ({ payload: { vacolsId } })
    },
    setOpenedAccordionSections: {
      reducer: (state, action) => {
        state.openedAccordionSections = action.payload.openedAccordionSections;
      },
      prepare: (openedAccordionSections, prevSections) => ({
        payload: { openedAccordionSections },
        meta: {
          analytics: (triggerEvent) => {
            const addedSectionKeys = difference(openedAccordionSections, prevSections);
            const removedSectionKeys = difference(prevSections, openedAccordionSections);

            addedSectionKeys.forEach(
              (newKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'opened-accordion-section', newKey)
            );
            removedSectionKeys.forEach(
              (oldKey) => triggerEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'closed-accordion-section', oldKey)
            );
          }
        }
      })
    },
    togglePdfSidebar: {
      reducer: (state, action) => {
        state.loadedAppealId = action.payload.vacolsId;
      },
      prepare: () =>
        addMetaLabel('toggle-pdf-sidebar', null, (state) => state.hidePdfSidebar ? 'hide' : 'show')
    },
    toggleSearchBar: (state) => {
      state.hidePdfSidebar = !state.hidePdfSidebar;
    },
    showSearchBar: (state) => {
      state.hideSearchBar = false;
    },
    hideSearchBar: (state) => {
      state.hideSearchBar = true;
    },
    resetSidebarErrors: (state) => {
      state.pdfSideBarError = initialPdfSidebarErrorState;
    },
    handleFinishScrollToSidebarComment: (state) => {
      state.scrollToSidebarComment = null;
    },
    setZoomLevel: {
      reducer: (state, action) => {
        state.scale = action.payload.scale;
      },
      prepare: (scale) => ({ payload: { scale } })
    },
    handleSetOverscanValue: {
      reducer: (state, action) => {
        state.windowingOverscan = action.payload.overscanValue;
      },
      prepare: (overscanValue) => ({ payload: { overscanValue } })
    }
  },
  extraReducers: (builder) => {
    builder.
      addCase(fetchAppealDetails.fulfilled, (state, action) => {
        state.loadedAppeal = action.payload.appeal.data.attributes;
      }).
      addCase(fetchAppealDetails.rejected, (state) => {
        state.didLoadAppealFail = true;
      }).
      addMatcher((action) => [
        collectAllTags,
        removeTag.fulfilled,
        addTag.fulfilled,
        loadDocuments.fulfilled
      ].includes(action.type),
      (state, action) => {
        // Set the documents based on the action
        const documents = action.type === loadDocuments.fulfilled ?
          action.payload.documents :
          state.reader.documents.list;

        // Update the tag options
        state.tagOptions = uniqWith(Object.keys(documents).map((doc) =>
          documents[doc].tags || []), isEqual);

        // Set the Appeal ID if loading documents
        if (action.type === loadDocuments.fulfilled) {
          state.loadedAppealId = action.payload.vacolsId;
        }
      }).
      // Match any actions that should hide the annotations error messages
      addMatcher(
        (action) => [
          stopPlacingAnnotation,
          editAnnotation.pending,
          editAnnotation.fulfilled,
          moveAnnotation.pending,
          moveAnnotation.fulfilled,
          deleteAnnotation.pending,
          deleteAnnotation.fulfilled,
        ].includes(action.type),
        (state) => setErrorMessageState(state, 'annotation', false)
      ).
      // Match any actions that should show the annotations error messages
      addMatcher(
        (action) => [
          editAnnotation.rejected,
          moveAnnotation.rejected,
          deleteAnnotation.rejected
        ].includes(action.type),
        (state, action) => setErrorMessageState(state, 'annotation', true, action.payload.errorMessage)).
      // Match any actions that should hide the tag error messages
      addMatcher(
        (action) => [
          removeTag.fulfilled,
          removeTag.pending,
          addTag.fulfilled,
          addTag.pending
        ].includes(action.type),
        (state) => setErrorMessageState(state, 'tag', false)
      ).
      // Match any actions that should show the tag error messages
      addMatcher(
        (action) => [
          removeTag.rejected,
          addTag.rejected
        ].includes(action.type),
        (state, action) => setErrorMessageState(state, 'tag', true, action.payload.errorMessage)).
      // Match any actions that should hide the category error messages
      addMatcher(
        (action) => [
          handleCategoryToggle.fulfilled
        ].includes(action.type),
        (state) => setErrorMessageState(state, 'category', false)
      ).
      // Match any actions that should show the category error messages
      addMatcher(
        (action) => [
          toggleDocumentCategoryFail,
          handleCategoryToggle.rejected
        ].includes(action.type),
        (state, action) => setErrorMessageState(state, 'category', true, action.payload.errorMessage)).
      // Match any actions that should hide the description error messages
      addMatcher(
        (action) => [
          changePendingDocDescription,
          resetPendingDocDescription
        ].includes(action.type),
        (state) => setErrorMessageState(state, 'description', false)
      ).
      // Match any actions that should show the description error messages
      addMatcher(
        (action) => [
          saveDocumentDescription.rejected
        ].includes(action.type),
        (state, action) => setErrorMessageState(state, 'description', true, action.payload.errorMessage))
    ;
  }
});

// Export the Reducer actions
export const {
  jumpToPage,
  resetJumpToPage,
  handleSelectCommentIcon,
  setDocScrollPosition,
  setLoadedVacolsId,
  setOpenedAccordionSections,
  togglePdfSidebar,
  toggleSearchBar,
  showSearchBar,
  hideSearchBar,
  resetSidebarErrors,
  handleFinishScrollToSidebarComment,
  setZoomLevel,
  handleSetOverscanValue
} = pdfViewerSlice.actions;

// Default export the reducer
export default pdfViewerSlice.reducer;

