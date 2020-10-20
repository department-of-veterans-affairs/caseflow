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
