// External Dependencies
import React from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';

// Internal Dependencies
import { onScrollToComment } from 'app/reader/Pdf/PdfActions';
import { setCategoryFilter } from 'app/reader/DocumentList/DocumentListActions';
import { fetchAppealDetails, showSearchBar } from 'app/reader/PdfViewer/PdfViewerActions';
import { getFilteredDocuments } from 'app/reader/selectors';

import { selectCurrentPdf, closeDocumentUpdatedModal } from 'app/reader/Documents/DocumentsActions';
import {
  stopPlacingAnnotation,
  showPlaceAnnotationIcon,
  deleteAnnotation,
  closeAnnotationDeleteModal,
  closeAnnotationShareModal
} from 'app/reader/AnnotationLayer/AnnotationActions';

const Document = () => {
  const dispatch = useDispatch();

  return <React.Fragment />;
};

Document.propTypes = {
  annotations: PropTypes.object,
  appeal: PropTypes.object,
  closeAnnotationDeleteModal: PropTypes.func,
  closeAnnotationShareModal: PropTypes.func,
  closeDocumentUpdatedModal: PropTypes.func,
  deleteAnnotation: PropTypes.func,
  doc: PropTypes.object,
  documentPathBase: PropTypes.string,
  featureToggles: PropTypes.object,
  fetchAppealDetails: PropTypes.func,
  handleSelectCurrentPdf: PropTypes.func,
  history: PropTypes.object,
  isPlacingAnnotation: PropTypes.bool,
  match: PropTypes.object,
  onJumpToComment: PropTypes.func,
  onScrollToComment: PropTypes.func,
  pageDimensions: PropTypes.object,
  pdfWorker: PropTypes.string,
  placingAnnotationIconPageCoords: PropTypes.object,
  scrollToComment: PropTypes.shape({
    id: PropTypes.number
  }),
  showPlaceAnnotationIcon: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  deleteAnnotationModalIsOpenFor: PropTypes.number,
  shareAnnotationModalIsOpenFor: PropTypes.number,
  documents: PropTypes.array.isRequired,
  allDocuments: PropTypes.array.isRequired,
  selectCurrentPdf: PropTypes.func,
  hidePdfSidebar: PropTypes.bool,
  showPdf: PropTypes.func
};

export default Document;
