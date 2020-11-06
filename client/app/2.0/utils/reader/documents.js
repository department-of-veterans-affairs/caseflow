// External Dependencies
import { sortBy, round } from 'lodash';

// Local Dependencies
import {
  documentCategories,
  MINIMUM_ZOOM,
  DOCUMENTS_OR_COMMENTS_ENUM,
  CATEGORIES,
  ACTION_NAMES,
  INTERACTION_TYPES
} from 'store/constants/reader';
import { formatCategoryName } from 'utils/reader/format';
import { setZoomLevel } from 'store/reader/pdfViewer';
import { stopPlacingAnnotation } from 'store/reader/annotationLayer';

/**
 * Helper Method to Calculate the Documents List View
 * @param {array} documents -- List of documents for the selected appeal
 * @param {Object} filter -- The Document Filter Criteria
 * @param {string} view -- The Currently selected view `viewingDocumentsOrComments`
 * @returns {string} -- The type of view to load in the documents list
 */
export const documentsView = (documents, filter, view) => {
  // Return no Results if there are no documents found matching the search
  if (!documents.length && filter.searchQuery.length > 0) {
    return 'none';
  }

  // Set the Comments view if viewing the Comments table
  if (view === DOCUMENTS_OR_COMMENTS_ENUM.COMMENTS) {
    return 'comments';
  }

  // Default to return the documents table
  return 'documents';
};

/**
 * Helper Method to Calculate the Document Rows
 * @param {array} documents -- The list of documents for the selected appeal
 * @param {array} annotationsPerDocument -- The list of comments for each document
 * @returns {array} -- The list of comment rows for the table
 */
export const documentRows = (documents, annotationsPerDocument) => documents.reduce((acc, doc) => {
  acc.push(doc);
  const docHasComments = annotationsPerDocument[doc.id].length;

  if (docHasComments && doc.listComments) {
    acc.push({
      ...doc,
      isComment: true
    });
  }

  return acc;
}, []);

/**
 * Helper Method to get the Categories for each Document
 * @param {Object} document -- The Document to get categories
 */
export const categoriesOfDocument = (document) =>
  sortBy(documentCategories.filter((category, categoryName) =>
    document[formatCategoryName(categoryName)]), 'renderOrder');

/**
 * Helper Method to set the Zoom of the Document
 * @param {number} delta -- The Change in zoom
 * @param {number} scale -- The current scale
 * @param {Function} dispatch -- Redux Dispatcher to update the store
 */
export const zoom = (delta, scale, dispatch) => () => {
  // Calculate the change in scale
  const nextScale = Math.max(MINIMUM_ZOOM, round(scale + delta, 2));

  // Calculate the zoom direction
  const zoomDirection = delta > 0 ? 'in' : 'out';

  // Update the windows analytics with the action
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, `zoom ${zoomDirection}`, nextScale);

  // Update the store with the new scale
  dispatch(setZoomLevel(nextScale));
};

/**
 * Helper Method to download the document
 * @param {string} contentUrl -- The absolute path to the document
 * @param {string} type -- The type of document
 */
export const openDownloadLink = (contentUrl, type) => {
  // Update the windows analytics with the action
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'download');

  // Trigger the file download
  window.open(`${contentUrl}?type=${type}&download=true`);
};

/**
 * Helper Method to change to the previous document
 * @param {string} docId -- The ID of the previous document
 * @param {Function} showPdf -- Helper method that changes documents
 * @param {Function} dispatch -- Redux Dispatcher to update the store
 */
export const showPreviousDocument = (docId, showPdf, dispatch) => {
  // Update the windows analytics with the action
  window.analyticsEvent(
    CATEGORIES.VIEW_DOCUMENT_PAGE,
    ACTION_NAMES.VIEW_PREVIOUS_DOCUMENT,
    INTERACTION_TYPES.VISIBLE_UI
  );

  // Change to the Previous document
  showPdf(docId);

  // Update the annotation state
  dispatch(stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI));
};

/**
 * Helper Method to change to the previous document
 * @param {string} docId -- The ID of the previous document
 * @param {Function} showPdf -- Helper method that changes documents
 * @param {Function} dispatch -- Redux Dispatcher to update the store
 */
export const showNextDocument = (docId, showPdf, dispatch) => {
  // Update the windows analytics with the action
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, ACTION_NAMES.VIEW_NEXT_DOCUMENT, INTERACTION_TYPES.VISIBLE_UI);

  // Change to the next Document
  showPdf(docId);

  // Update the annotation state
  dispatch(stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI));
};

/**
 * Helper Method to adjust the Document to fit the current screen
 * @param {number} scale -- The scale the screen is currently
 * @param {number} zoomLevel -- The Current Zoom Level
 * @param {Function} dispatch -- Redux Dispatcher to update the store
 */
export const fitToScreen = (scale, zoomLevel, dispatch) => {
  // Update the window analytics with the current action
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'fit to screen');

  // Toggle fit to screen property.
  if (scale === zoomLevel) {
    dispatch(setZoomLevel(1));
  } else {
    dispatch(setZoomLevel(zoom));
  }
};

/**
 * Helper Method to get the page number by page index
 * @param {number} index -- The index of the current page
 */
export const pageNumber = (index) => index + 1;

/**
 * Helper Method to get the index number by page number
 * @param {number} number -- The number of the current page
 */
export const pageIndex = (number) => number - 1;

/**
 * Helper Method to translate the rotation into X coordinates
 * @param {number} rotation -- The current document rotation
 * @param {number} outerHeight -- The height of the containing element
 * @param {number} outerWidth -- The width of the containing element
 */
export const translateX = (rotation, outerHeight, outerWidth) =>
  Math.sin((rotation / 180) * Math.PI) * (outerHeight - outerWidth) / 2;

/**
 * Helper Method to count the number of columns for a specific page
 * @param {number} width -- The Width of the screen
 * @param {number} pageWidth -- The Width of the page
 * @param {number} numPages -- The number of pages
 */
export const columnCount = (width, pageWidth, numPages) =>
  Math.min(Math.max(Math.floor(width / pageWidth), 1), numPages);
