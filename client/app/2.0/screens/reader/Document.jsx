// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies

const Document = () => {

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
