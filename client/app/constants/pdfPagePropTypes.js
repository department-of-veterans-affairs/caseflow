import PropTypes from 'prop-types';

export const pdfPagePropTypes = {
  currentMatchIndex: PropTypes.any,
  documentId: PropTypes.number,
  documentType: PropTypes.any,
  file: PropTypes.string,
  getTextLayerRef: PropTypes.func,
  handleSelectCommentIcon: PropTypes.func,
  isDrawing: PropTypes.any,
  isFileVisible: PropTypes.bool,
  isPageVisible: PropTypes.any,
  isPlacingAnnotation: PropTypes.any,
  isVisible: PropTypes.bool,
  matchesPerPage: PropTypes.shape({
    length: PropTypes.any
  }),
  metricsIdentifier: PropTypes.string,
  page: PropTypes.shape({
    cleanup: PropTypes.func
  }),
  pageDimensions: PropTypes.any,
  pageIndex: PropTypes.number,
  pageIndexWithMatch: PropTypes.any,
  pdfDocument: PropTypes.object,
  placingAnnotationIconPageCoords: PropTypes.object,
  relativeIndex: PropTypes.any,
  rotate: PropTypes.number,
  rotation: PropTypes.number,
  scale: PropTypes.number,
  searchBarHidden: PropTypes.bool,
  searchText: PropTypes.string,
  setDocScrollPosition: PropTypes.func,
  setSearchIndexToHighlight: PropTypes.func,
  windowingOverscan: PropTypes.string,
  featureToggles: PropTypes.object,
  measureTimeStartMs: PropTypes.number
};
