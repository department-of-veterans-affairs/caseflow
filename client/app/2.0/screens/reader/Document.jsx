// External Dependencies
import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

// Internal Dependencies
import { setAppeal } from 'utils';
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
import { setDocumentDetails } from 'utils/reader';

const Document = () => (
  <React.Fragment />
);

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

const mapStateToProps = (state, props) => ({
  ...setDocumentDetails(state),
  documents: getFilteredDocuments(state),
  annotations: state.annotationLayer.annotations,
  documentFilters: state.documentList.pdfList.filters,
  storeDocuments: state.documents,
  isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation,
  appeal: setAppeal(state, props)
});

const mapDispatchToProps = {
  fetchAppealDetails,
  onScrollToComment,
  setCategoryFilter,
  stopPlacingAnnotation,
  showPlaceAnnotationIcon,
  closeAnnotationShareModal,
  closeAnnotationDeleteModal,
  deleteAnnotation,
  showSearchBar,
  closeDocumentUpdatedModal,
  handleSelectCurrentPdf: selectCurrentPdf
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Document);
