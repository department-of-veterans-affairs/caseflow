// External Dependencies
import { memoize } from 'lodash';

// Local Dependencies
import { getQueryParams } from 'app/util/QueryParamsUtil';
import { CATEGORIES } from '../store/constants/reader';
import { setCategoryFilter } from '../store/documentList';

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
 * Method to initialize the category Filters
 * @param {array} categories -- The list of categories available
 * @param {string} search -- The Query Search from the URL bar
 * @param {function} dispatch -- The Redux Dispatcher
 */
export const initCategoryFilter = (categories, search, dispatch) => {
  // Calculate the Query Params
  const queryParams = getQueryParams(search);
  const category = queryParams.category;

  // If the category is available apply the filter to the store
  if (categories[category]) {
    dispatch(setCategoryFilter(category, true));

    // Clear out the URI query string params after we determine the initial
    // category filter so that we do not continue to attempt to set the
    // category filter every time routedPdfListView renders.
    return '';
  }

  // Default to return the search so we don't clear
  return search;
};

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
