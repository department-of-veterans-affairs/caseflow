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
 * Helper Method to update the focus of the Documents Table
 * @param {element} lastReadRef -- React ref to the current Last Read Indicator
 * @param {element} tbodyRef -- React ref to the current Table Body
 */
export const focusElement = (lastReadRef, tbodyRef) => {
  // Set the Initial Scroll position
  let scrollTop = tbodyRef.scrollTop;

  // Focus the Last Read Indicator if present
  if (lastReadRef) {
    // Get the Last Read Indicator Boundary
    const lastReadContainer = lastReadRef.getBoundingClientRect();

    // Get the Table Body Boundary
    const tbodyContainer = tbodyRef.getBoundingClientRect();

    // Check if the Last Read Indicator is in view based on whether it is in the table body boundary
    if (tbodyContainer.top >= lastReadContainer.top && lastReadContainer.bottom >= tbodyContainer.bottom) {
      // Find the row to focus
      const rowWithLastRead = find(tbodyRef.children, (tr) => tr.querySelector(`#${lastReadRef.id}`));

      // Update the scroll position to focus the Last Read Row
      scrollTop += rowWithLastRead.getBoundingClientRect().top - tbodyContainer.top;
    }
  }

  // Return the Scroll Position to update the table
  return scrollTop;
};

/**
 * This is a dummy method that will be replaced in a later part of the stack
 */
export const documentRows = () => [];
