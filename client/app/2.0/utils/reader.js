import { formatNameShort } from 'app/util/FormatUtil';
import { find, pick } from 'lodash';

export const getClaimsFolderPageTitle = (appeal) => appeal && appeal.veteran_first_name ?
  `${formatNameShort(appeal.veteran_first_name, appeal.veteran_last_name)}'s Claims Folder` :
  'Claims Folder | Caseflow Reader';

export const setAppeal = (state, props) => props.match?.params?.vacolsId ?
  find(state.caseSelect.assignments, { vacols_id: props.match.params.vacolsId }) :
  state.pdfViewer.loadedAppeal;

export const setDocumentDetails = (state) => ({
  ...pick(state.documentList, 'docFilterCriteria', 'viewingDocumentsOrComments'),
  ...pick(state.pdfViewer, 'hidePdfSidebar'),
  ...pick(state.pdf, 'scrollToComment', 'pageDimensions'),
  ...pick(state.annotationLayer,
    'placingAnnotationIconPageCoords',
    'deleteAnnotationModalIsOpenFor',
    'shareAnnotationModalIsOpenFor',
    'placedButUnsavedAnnotation',
    'isPlacingAnnotation'
  ),
});

/**
 * Helper Method to display search text on document search
 * @param {string} searchTerm -- The term which is being search
 * @param {number} totalMatchesInFile -- The total matches to the search term in the current file
 * @param {number} currentMatchIndex -- The Current Index of the match
 */
export const formatSearchText = (searchTerm, totalMatchesInFile, currentMatchIndex) => {
  // Check the match index if there is a search term
  if (searchTerm.length) {
    // Return the Matches in file if found
    if (totalMatchesInFile > 0) {
      return `${currentMatchIndex + 1} of ${totalMatchesInFile}`;
    } else if (totalMatchesInFile > 9999) {
      return `${currentMatchIndex + 1} of many`;
    }

    // Return zero matches if none found
    return '0 of 0';
  }

  // Default to return empty text
  return '';
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

