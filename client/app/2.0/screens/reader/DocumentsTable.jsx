// External Dependencies
import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { pick } from 'lodash';

// Internal Dependencies
import { setAppeal } from 'utils';
import { onScrollToComment } from 'app/reader/Pdf/PdfActions';
import { setCategoryFilter } from 'app/reader/DocumentList/DocumentListActions';
import { stopPlacingAnnotation } from 'app/reader/AnnotationLayer/AnnotationActions';
import { fetchAppealDetails, onReceiveAppealDetails } from 'app/reader/PdfViewer/PdfViewerActions';
import { getFilteredDocuments } from 'app/reader/selectors';

const DocumentsTable = () => (
  <React.Fragment />
);

DocumentsTable.propTypes = {
  appeal: PropTypes.object,
  pdfWorker: PropTypes.string,
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  singleDocumentMode: PropTypes.bool,

  // Required actions
  onScrollToComment: PropTypes.func,
  stopPlacingAnnotation: PropTypes.func,
  setCategoryFilter: PropTypes.func
};

const mapStateToProps = (state, props) => ({
  ...pick(state.documentList, 'docFilterCriteria', 'viewingDocumentsOrComments'),
  documents: getFilteredDocuments(state),
  caseSelectedAppeal: state.caseSelect.selectedAppeal,
  manifestVbmsFetchedAt: state.documentList.manifestVbmsFetchedAt,
  manifestVvaFetchedAt: state.documentList.manifestVvaFetchedAt,
  queueRedirectUrl: state.documentList.queueRedirectUrl,
  queueTaskType: state.documentList.queueTaskType,
  documentFilters: state.documentList.pdfList.filters,
  storeDocuments: state.documents,
  isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation,
  appeal: setAppeal(state, props)
});

const mapDispatchToProps = {
  onReceiveAppealDetails,
  fetchAppealDetails,
  onScrollToComment,
  setCategoryFilter,
  stopPlacingAnnotation
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DocumentsTable);
