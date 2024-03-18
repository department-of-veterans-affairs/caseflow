// External Dependencies
import { memoize } from 'lodash';

// Local Dependencies
import { CATEGORIES } from 'store/constants/reader';

/**
 * Method to change to Single Document Mode
 */
export const singleDocumentMode = memoize(() =>
  window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'single-document-mode'));

/**
 * Method to navigate between PDF files
 * @param {Object} history -- The Browser Router History Object
 * @param {number} vacolsId -- The ID of the Appeal in VACOLS
 */
export const showPdf = (history, vacolsId) => (documents, docId) =>
  documents[docId] && history.push(`/${vacolsId}/documents/${docId}`);

/**
 * Helper Method to return the Annotation ID
 * @param {Object} annotation -- The ID and TempID of the annotation
 * @returns {string} -- The ID of the annotation
 */
export const keyOfAnnotation = ({ tempId, id }) => tempId || id;

/**
 * Helper Method to calculate the next page index
 * @param {number} pageIndex -- The index of the page
 */
export const pageNumberOfPageIndex = (pageIndex) => pageIndex + 1;

/**
 * Helper Method to calculate the next page number
 * @param {number} pageNumber -- The number of the page
 */
export const pageIndexOfPageNumber = (pageNumber) => pageNumber - 1;

/**
 * Helper Method to determine a valid whole number
 * @param {number} number -- The number to check against
 * @returns {boolean} -- Whether the number is a valid whole number or not
 */
export const isValidWholeNumber = (number) => {
  return !isNaN(number) && number % 1 === 0;
};
