import React from 'react';
import PropTypes from 'prop-types';

import { bindActionCreators } from 'redux';

import { isUserEditingText, pageNumberOfPageIndex, pageIndexOfPageNumber,
  pageCoordsOfRootCoords, rotateCoordinates } from '../reader/utils';
import PdfFile from '../reader/PdfFile';
import { connect } from 'react-redux';
import _ from 'lodash';
import { togglePdfSidebar } from '../reader/actions';
import { onScrollToComment } from '../reader/Pdf/PdfActions';
import { placeAnnotation, startPlacingAnnotation,
  stopPlacingAnnotation, showPlaceAnnotationIcon
} from '../reader/PdfViewer/AnnotationActions';

import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';
import { INTERACTION_TYPES, CATEGORIES } from '../reader/analytics';
import DocumentSearch from './DocumentSearch';

/**
 * We do a lot of work with coordinates to render PDFs.
 * It is important to keep the various coordinate systems straight.
 * Here are the systems we use:
 *
 *    Root coordinates: The coordinate system for the entire app.
 *      (0, 0) is the top left hand corner of the entire HTML document that the browser has rendered.
 *
 *    Page coordinates: A coordinate system for a given PDF page.
 *      (0, 0) is the top left hand corner of that PDF page.
 *
 * The relationship between root and page coordinates is defined by where the PDF page is within the whole app,
 * and what the current scale factor is.
 *
 * All coordinates in our codebase should have `page` or `root` in the name, to make it clear which
 * coordinate system they belong to. All converting between coordinate systems should be done with
 * the proper helper functions.
 */
export const getInitialAnnotationIconPageCoords = (iconPageBoundingBox, scrollWindowBoundingRect, scale) => {
  const leftBound = Math.max(scrollWindowBoundingRect.left, iconPageBoundingBox.left);
  const rightBound = Math.min(scrollWindowBoundingRect.right, iconPageBoundingBox.right);
  const topBound = Math.max(scrollWindowBoundingRect.top, iconPageBoundingBox.top);
  const bottomBound = Math.min(scrollWindowBoundingRect.bottom, iconPageBoundingBox.bottom);

  const rootCoords = {
    x: _.mean([leftBound, rightBound]),
    y: _.mean([topBound, bottomBound])
  };

  const pageCoords = pageCoordsOfRootCoords(rootCoords, iconPageBoundingBox, scale);

  const annotationIconOffset = ANNOTATION_ICON_SIDE_LENGTH / 2;

  return {
    x: pageCoords.x - annotationIconOffset,
    y: pageCoords.y - annotationIconOffset
  };
};

const COVER_SCROLL_HEIGHT = 120;

// The Pdf component encapsulates PDFJS to enable easy drawing of PDFs.
// The component will speed up drawing by only drawing pages when
// they become visible.
export class Pdf extends React.PureComponent {
  handleAltC = () => {
    if (this.props.sidebarHidden) {
      this.props.togglePdfSidebar();
    }

    this.props.startPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);

    const scrollWindowBoundingRect = this.scrollWindow.getBoundingClientRect();
    const firstPageWithRoomForIconIndex = pageIndexOfPageNumber(this.currentPage);

    const iconPageBoundingBox =
      this.props.pageContainers[firstPageWithRoomForIconIndex].getBoundingClientRect();

    const pageCoords = getInitialAnnotationIconPageCoords(
      iconPageBoundingBox,
      scrollWindowBoundingRect,
      this.props.scale
    );

    this.props.showPlaceAnnotationIcon(firstPageWithRoomForIconIndex, pageCoords);
  }

  handleAltEnter = () => {
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
      if (event.code === 'KeyC') {
        this.handleAltC();
      }

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

  componentWillReceiveProps(nextProps) {
    // In general I think this is a good lint rule. However,
    // I think the below statements are clearer
    // with negative conditions.
    /* eslint-disable no-negated-condition */
    if (nextProps.file !== this.props.file) {
      this.scrollWindow.scrollTop = 0;

      // focus the scroll window when the document changes.
      this.scrollWindow.focus();
    } else if (nextProps.scale !== this.props.scale && this.props.pageContainers) {
      // Set the scroll location based on the current page and where you
      // are on that page scaled by the zoom factor.
      const zoomFactor = nextProps.scale / this.props.scale;
      const nonZoomedLocation = (this.scrollWindow.scrollTop -
        this.props.pageContainers[this.currentPage - 1].offsetTop);

      this.scrollLocation = {
        page: this.currentPage,
        locationOnPage: nonZoomedLocation * zoomFactor
      };
    }
    /* eslint-enable no-negated-condition */
  }

  scrollToPage(pageNumber) {
    this.scrollWindow.scrollTop =
      this.props.pageContainers[pageNumber - 1].getBoundingClientRect().top +
      this.scrollWindow.scrollTop - COVER_SCROLL_HEIGHT;
  }

  // eslint-disable-next-line max-statements
  componentDidUpdate() {
    // Wait until the page dimensions have been calculated, then it is
    // safe to jump to the pages since their positioning won't change.
    if (this.props.arePageDimensionsSet) {
      if (this.props.jumpToPageNumber) {

        // this.scrollToPage(this.props.jumpToPageNumber);
        // this.onPageChange(this.props.jumpToPageNumber);
      }
      if (this.props.scrollToComment) {
        const pageIndex = pageIndexOfPageNumber(this.props.scrollToComment.page);
        const y = rotateCoordinates(this.props.scrollToComment,
          this.props.pageContainers[pageIndex].getBoundingClientRect(), -this.props.rotation).y * this.props.scale;

        this.scrollToPageLocation(pageIndex, y);
      }
    }

    if (this.scrollLocation.page) {
      this.scrollWindow.scrollTop = this.scrollLocation.locationOnPage +
        this.props.pageContainers[this.scrollLocation.page - 1].offsetTop;
    }
  }

  getScrollWindowRef = (scrollWindow) => {
    this.scrollWindow = scrollWindow;
    this.updateScrollWindowCenter();
  }

  // eslint-disable-next-line max-statements
  render() {
    const scrollTop = this.scrollWindow ? this.scrollWindow.scrollTop : 0;
    const pages = [...this.props.prefetchFiles, this.props.file].map((file) => {
      return <PdfFile
        pdfWorker={this.props.pdfWorker}
        documentId={this.props.documentId}
        key={`${file}`}
        file={file}
        onPageChange={this.props.onPageChange}
        isVisible={this.props.file === file}
        scale={this.props.scale}
      />;
    });
// <div
//       id="scrollWindow"
//       tabIndex="0"
//       className="cf-pdf-scroll-view"
//       onScroll={this.scrollEvent}
//       ref={this.getScrollWindowRef}>
    return <div className="cf-pdf-scroll-view">
      {global.featureToggles.search && <DocumentSearch file={this.props.file} />}
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
  // Gets page keys where the container is defined.
  // const pages = state.readerReducer.pages[props.file];
  // const numPagesDefined = pages.length;
  // const pdfDocument = state.readerReducer.pdfDocuments[props.file];
  // const numPages = pdfDocument ? pdfDocument.pdfInfo.numPages : -1;
  // let pageContainers = null;

  // if (numPagesDefined === numPages) {
  //   pageContainers = pageKeys.reduce((acc, key) => {
  //     const pageIndex = key.split('-')[1];

  //     acc[pageIndex] = state.readerReducer.pages[key] ? state.readerReducer.pages[key].container : null;

  //     return acc;
  //   }, {});
  // }

  return {
    ...state.readerReducer.ui.pdf,
    arePageDimensionsSet: false,
    pageContainers: null,
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
