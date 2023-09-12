import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';

import { isUserEditingText, pageNumberOfPageIndex } from '../reader/utils';
import PdfFile from '../reader/PdfFile';
import { connect } from 'react-redux';
import _ from 'lodash';
import { togglePdfSidebar } from '../reader/PdfViewer/PdfViewerActions';
import { placeAnnotation, startPlacingAnnotation,
  stopPlacingAnnotation, showPlaceAnnotationIcon
} from '../reader/AnnotationLayer/AnnotationActions';

import { INTERACTION_TYPES, CATEGORIES } from '../reader/analytics';

// The Pdf component encapsulates PDFJS to enable easy drawing of PDFs.
// The component will speed up drawing by only drawing pages when
// they become visible.
export class Pdf extends React.PureComponent {
  handleAltEnter = () => {
    if (this.props.placingAnnotationIconPageCoords) {
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
  }

  handleAltBackspace = () => {
    window.analyticsEvent(CATEGORIES.VIEW_DOCUMENT_PAGE, 'back-to-claims-folder');
    this.props.stopPlacingAnnotation('from-back-to-documents');
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
  loadDocs = (arr) => {
    return arr.map((file) => {
      return <PdfFile
        documentId={this.props.documentId}
        key={`${file}`}
        file={file}
        onPageChange={this.props.onPageChange}
        isVisible={this.props.file === file}
        scale={this.props.scale}
        documentType={this.props.documentType}
        featureToggles={this.props.featureToggles}
      />;
    });
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
    const files = this.props.featureToggles.prefetchDisabled ?
      [this.props.file] : [...this.props.prefetchFiles, this.props.file];

    return <div className="cf-pdf-scroll-view">
      <div
        id={this.props.file}
        style={{
          position: 'relative',
          width: '100%',
          height: '100%'
        }}>
        {this.loadDocs(files)}
      </div>
    </div>;
  }
}

const mapStateToProps = (state, props) => {
  return {
    ..._.pick(state.annotationLayer, 'placingAnnotationIconPageCoords'),
    rotation: _.get(state.documents, [props.documentId, 'rotation']),
    sidebarHidden: state.pdfViewer.hidePdfSidebar,
    isPlacingAnnotation: state.annotationLayer.isPlacingAnnotation
  };
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    placeAnnotation,
    startPlacingAnnotation,
    stopPlacingAnnotation,
    showPlaceAnnotationIcon,
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
  documentId: PropTypes.number.isRequired,
  documentPathBase: PropTypes.any,
  documentType: PropTypes.any,
  file: PropTypes.string.isRequired,
  history: PropTypes.shape({
    push: PropTypes.func
  }),
  isPlacingAnnotation: PropTypes.any,
  onIconMoved: PropTypes.func,
  onPageChange: PropTypes.func,
  placeAnnotation: PropTypes.func,
  placingAnnotationIconPageCoords: PropTypes.shape({
    pageIndex: PropTypes.any,
    x: PropTypes.any,
    y: PropTypes.any
  }),
  prefetchFiles: PropTypes.arrayOf(PropTypes.string),
  rotation: PropTypes.number,
  scale: PropTypes.number,
  selectedAnnotationId: PropTypes.number,
  stopPlacingAnnotation: PropTypes.func,
  togglePdfSidebar: PropTypes.func,
  featureToggles: PropTypes.object
};
