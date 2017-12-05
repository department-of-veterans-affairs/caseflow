import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';

import { isUserEditingText, pageNumberOfPageIndex } from '../reader/utils';
import PdfFile from '../reader/PdfFile';
import { connect } from 'react-redux';
import _ from 'lodash';
import { togglePdfSidebar } from '../reader/PdfViewer/PdfViewerActions';
import { onScrollToComment } from '../reader/Pdf/PdfActions';
import { placeAnnotation, startPlacingAnnotation,
  stopPlacingAnnotation, showPlaceAnnotationIcon
} from '../reader/AnnotationLayer/AnnotationActions';

import { INTERACTION_TYPES, CATEGORIES } from '../reader/analytics';

// The Pdf component encapsulates PDFJS to enable easy drawing of PDFs.
// The component will speed up drawing by only drawing pages when
// they become visible.
export class Pdf extends React.PureComponent {
  handleAltEnter = () => {
    // todo: this is only triggered if not editing a comment--EditComment listens to alt+enter when active
    this.props.placeAnnotation(
      pageNumberOfPageIndex(this.props.placingAnnotationIconPageCoords.pageIndex),
      {
        xPosition: this.props.placingAnnotationIconPageCoords.x,
        yPosition: this.props.placingAnnotationIconPageCoords.y
      },
      this.props.documentId
    );
  }

  handleAltBackspace = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
    this.props.stopPlacingAnnotation(INTERACTION_TYPES.VISIBLE_UI);
    this.props.history.push(this.props.documentPathBase);
  }

  keyListener = (event) => {
    if (isUserEditingText()) {
      return;
    }

    if (event.altKey) {
      if (event.code === 'Enter') {
        this.handleAltEnter();
      }

      if (event.code === 'Backspace') {
        this.handleAltBackspace();
      }
    }

    if (event.code === 'Escape' && this.props.isPlacingAnnotation) {
      this.props.stopPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);
    }
  }

  componentDidMount() {
    window.addEventListener('keydown', this.keyListener);
    window.addEventListener('resize', this.updateScrollWindowCenter);
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateScrollWindowCenter);
    window.removeEventListener('keydown', this.keyListener);
  }

  // eslint-disable-next-line max-statements
  render() {
    const pages = [...this.props.prefetchFiles, this.props.file].map((file) => {
      return <PdfFile
        pdfWorker={this.props.pdfWorker}
        documentId={this.props.documentId}
        key={`${file}`}
        file={file}
        onPageChange={this.props.onPageChange}
        isVisible={this.props.file === file}
        scale={this.props.scale}
        documentType={this.props.documentType}
      />;
    });

    return <div className="cf-pdf-scroll-view">
      <div
        id={this.props.file}
        style={{
          position: 'relative',
          width: '100%',
          height: '100%'
        }}>
        {pages}
      </div>
    </div>;
  }
}

const mapStateToProps = (state, props) => {
  return {
    ...state.readerReducer.ui.pdf,
    ..._.pick(state.readerReducer, 'placingAnnotationIconPageCoords'),
    rotation: _.get(state.readerReducer.documents, [props.documentId, 'rotation']),
    sidebarHidden: state.readerReducer.ui.pdf.hidePdfSidebar
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    placeAnnotation,
    startPlacingAnnotation,
    stopPlacingAnnotation,
    showPlaceAnnotationIcon,
    onScrollToComment,
    togglePdfSidebar
  }, dispatch)
});

export default connect(
  mapStateToProps, mapDispatchToProps
)(Pdf);

Pdf.defaultProps = {
  onPageChange: _.noop,
  prefetchFiles: [],
  scale: 1
};

Pdf.propTypes = {
  selectedAnnotationId: PropTypes.number,
  documentId: PropTypes.number.isRequired,
  file: PropTypes.string.isRequired,
  pdfWorker: PropTypes.string.isRequired,
  scale: PropTypes.number,
  onPageChange: PropTypes.func,
  scrollToComment: PropTypes.shape({
    id: PropTypes.number,
    page: PropTypes.number,
    y: PropTypes.number
  }),
  onIconMoved: PropTypes.func,
  prefetchFiles: PropTypes.arrayOf(PropTypes.string),
  rotation: PropTypes.number,
  togglePdfSidebar: PropTypes.func
};
