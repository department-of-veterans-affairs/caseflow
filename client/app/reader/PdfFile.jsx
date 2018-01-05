import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { resetJumpToPage, setDocScrollPosition } from '../reader/PdfViewer/PdfViewerActions';
import StatusMessage from '../components/StatusMessage';
import { PDF_PAGE_WIDTH, PDF_PAGE_HEIGHT, ANNOTATION_ICON_SIDE_LENGTH } from './constants';
import { setPdfDocument, clearPdfDocument, onScrollToComment, setDocumentLoadError, clearDocumentLoadError
} from '../reader/Pdf/PdfActions';
import { updateSearchIndexPage, updateSearchRelativeIndex } from '../reader/PdfSearch/PdfSearchActions';
import ApiUtil from '../util/ApiUtil';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer';
import { Grid, AutoSizer } from 'react-virtualized';
import { isUserEditingText, pageIndexOfPageNumber, pageNumberOfPageIndex, rotateCoordinates } from './utils';
import { startPlacingAnnotation, showPlaceAnnotationIcon
} from '../reader/AnnotationLayer/AnnotationActions';
import { INTERACTION_TYPES } from '../reader/analytics';
import { getCurrentMatchIndex, getMatchesPerPageInFile, text as searchText } from './selectors';

const PAGE_MARGIN = 25;

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.loadingTask = null;
    this.pdfDocument = null;
    this.grid = null;
    this.rowStartIndex = 0;
    this.scrollTop = 0;
    this.scrollLeft = 0;
    this.scrollLocation = {};
    this.clientHeight = 0;
    this.clientWidth = 0;
    this.currentPage = 0;
    this.columnCount = 1;
  }

  componentDidMount = () => {
    PDFJS.workerSrc = this.props.pdfWorker;

    let requestOptions = {
      cache: true,
      withCredentials: true,
      timeout: true,
      responseType: 'arraybuffer'
    };

    window.addEventListener('keydown', this.keyListener);

    this.props.clearDocumentLoadError(this.props.file);

    // We have to set withCredentials to true since we're requesting the file from a
    // different domain (eFolder), and still need to pass our credentials to authenticate.
    return ApiUtil.get(this.props.file, requestOptions).
      then((resp) => {
        this.loadingTask = PDFJS.getDocument({ data: resp.body });

        return this.loadingTask;
      }).
      then((pdfDocument) => {
        if (this.loadingTask.destroyed) {
          pdfDocument.destroy();
        } else {
          this.loadingTask = null;
          this.pdfDocument = pdfDocument;
          this.props.setPdfDocument(this.props.file, pdfDocument);
        }
      }).
      catch(() => {
        this.loadingTask = null;
        this.props.setDocumentLoadError(this.props.file);
      });
  }

  componentWillUnmount = () => {
    window.removeEventListener('keydown', this.keyListener);

    if (this.loadingTask) {
      this.loadingTask.destroy();
    }
    if (this.pdfDocument) {
      this.pdfDocument.destroy();
      this.props.clearPdfDocument(this.props.file, this.pdfDocument);
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.isVisible !== this.props.isVisible) {
      this.currentPage = 0;
    }

    if (this.grid && nextProps.scale !== this.props.scale) {
      // Set the scroll location based on the current page and where you
      // are on that page scaled by the zoom factor.
      const zoomFactor = nextProps.scale / this.props.scale;
      const nonZoomedLocation = (this.scrollTop - this.getOffsetForPageIndex(this.rowStartIndex).scrollTop);

      this.scrollLocation = {
        page: this.rowStartIndex,
        locationOnPage: nonZoomedLocation * zoomFactor
      };
    }
  }

  getPage = ({ rowIndex, columnIndex, key, style }) => {
    if ((this.columnCount * rowIndex) + columnIndex >= this.props.pdfDocument.pdfInfo.numPages) {
      return null;
    }

    return <div key={key} style={style}>
      <PdfPage
        scrollTop={this.props.scrollTop}
        scrollWindowCenter={this.props.scrollWindowCenter}
        documentId={this.props.documentId}
        file={this.props.file}
        pageIndex={(rowIndex * this.columnCount) + columnIndex}
        isVisible={this.props.isVisible}
        scale={this.props.scale}
        pdfDocument={this.props.pdfDocument}
      />
    </div>;
  }

  pageDimensions = (index) => this.props.pageDimensions[`${this.props.file}-${index}`]

  pageHeight = (index) =>
    _.get(this.pageDimensions(index), ['height'], this.props.baseHeight)

  pageWidth = (index) =>
    _.get(this.pageDimensions(index), ['width'], this.props.baseWidth)

  getRowHeight = ({ index }) => {
    const pageIndexStart = index * this.columnCount;
    const pageHeights = _.range(pageIndexStart, pageIndexStart + this.columnCount).
      map((pageIndex) => this.pageHeight(pageIndex));

    return (Math.max(...pageHeights) + PAGE_MARGIN) * this.props.scale;
  }

  getColumnWidth = () => {
    const maxPageWidth = _.range(0, this.props.pdfDocument.pdfInfo.numPages).
      reduce((maxWidth, pageIndex) => Math.max(this.pageWidth(pageIndex), maxWidth), 0);

    return (maxPageWidth + PAGE_MARGIN) * this.props.scale;
  }

  getGrid = (grid) => {
    this.grid = grid;

    if (this.grid) {
      // eslint-disable-next-line react/no-find-dom-node
      const domNode = ReactDOM.findDOMNode(this.grid);

      domNode.focus();
      this.grid.recomputeGridSize();
    }
  }

  pageRowAndColumn = (pageIndex) => ({
    rowIndex: Math.floor(pageIndex / this.columnCount),
    columnIndex: pageIndex % this.columnCount
  })

  getOffsetForPageIndex = (pageIndex) => this.grid.getOffsetForCell(this.pageRowAndColumn(pageIndex))

  scrollToPosition = (pageIndex, locationOnPage = 0) => {
    const position = this.getOffsetForPageIndex(pageIndex);

    this.grid.scrollToPosition({
      scrollLeft: position.scrollLeft,
      scrollTop: Math.max(position.scrollTop + locationOnPage, 0)
    });
  }

  jumpToPage = () => {
    // We want to jump to the page, after the react virtualized has initialized the scroll window.
    if (this.props.jumpToPageNumber && this.clientHeight > 0) {
      const scrollToIndex = this.props.jumpToPageNumber ? pageIndexOfPageNumber(this.props.jumpToPageNumber) : -1;

      this.grid.scrollToCell(this.pageRowAndColumn(scrollToIndex));
      this.props.resetJumpToPage();
    }
  }

  jumpToComment = () => {
    // We want to jump to the comment, after the react virtualized has initialized the scroll window.
    if (this.props.scrollToComment && this.clientHeight > 0) {
      const pageIndex = pageIndexOfPageNumber(this.props.scrollToComment.page);
      const transformedY = rotateCoordinates(this.props.scrollToComment,
        this.pageDimensions(pageIndex), -this.props.rotation).y * this.props.scale;
      const scrollToY = transformedY - (this.pageHeight(pageIndex) / 2);

      this.scrollToPosition(pageIndex, scrollToY);
      this.props.onScrollToComment(null);
    }
  }

  scrollWhenFinishedZooming = () => {
    if (this.scrollLocation.page) {
      this.scrollToPosition(this.scrollLocation.page, this.scrollLocation.locationOnPage);

      this.scrollLocation = {};
    }
  }

  scrollToScrollTop = (pageIndex, locationOnPage = this.props.scrollTop) => {
    this.scrollToPosition(pageIndex, locationOnPage);
    this.props.setDocScrollPosition(null);
  }

  getPageIndexofMatch = (matchIndex = this.props.currentMatchIndex) => {
    // get page, relative index of match at absolute index
    let cumulativeMatches = 0;

    for (let matchesPerPageIndex = 0; matchesPerPageIndex < this.props.matchesPerPage.length; matchesPerPageIndex++) {
      if (matchIndex < cumulativeMatches + this.props.matchesPerPage[matchesPerPageIndex].matches) {
        return {
          pageIndex: this.props.matchesPerPage[matchesPerPageIndex].pageIndex,
          relativeIndex: matchIndex - cumulativeMatches
        };
      }

      cumulativeMatches += this.props.matchesPerPage[matchesPerPageIndex].matches;
    }

    return {
      pageIndex: -1,
      relativeIndex: -1
    };
  }

  scrollToSearchTerm = (prevProps) => {
    const { pageIndex, relativeIndex } = this.getPageIndexofMatch();

    if (pageIndex === -1) {
      return;
    }

    const currentMatchChanged = this.props.currentMatchIndex !== prevProps.currentMatchIndex;
    const searchTextChanged = this.props.searchText !== prevProps.searchText;

    if (this.props.scrollTop !== null && this.props.scrollTop !== prevProps.scrollTop) {
      // after currentMatchIndex is updated, scrollTop gets set in PdfPage, and this gets called again
      this.scrollToScrollTop(pageIndex);
    } else if (currentMatchChanged || searchTextChanged) {
      this.props.updateSearchRelativeIndex(relativeIndex);
      this.props.updateSearchIndexPage(pageIndex);

      // if the page has been scrolled out of DOM, scroll back to it, setting scrollTop
      this.grid.scrollToCell(this.pageRowAndColumn(pageIndex));
    }
  }

  componentDidUpdate = (prevProps) => {
    if (this.grid && this.props.isVisible) {
      this.grid.recomputeGridSize();
      this.scrollWhenFinishedZooming();
      this.jumpToPage();
      this.jumpToComment();

      if (this.props.searchText && this.props.matchesPerPage.length) {
        this.scrollToSearchTerm(prevProps);
      }
    }
  }

  onSectionRendered = ({ rowStartIndex }) => {
    this.rowStartIndex = rowStartIndex;
  }

  onPageChange = (index, clientHeight) => {
    this.currentPage = index;
    this.props.onPageChange(pageNumberOfPageIndex(index), clientHeight / this.pageHeight(index));
  }

  onScroll = ({ clientHeight, scrollTop, scrollLeft }) => {
    this.scrollTop = scrollTop;
    this.scrollLeft = scrollLeft;

    if (this.grid) {
      let lastIndex = 0;

      _.range(0, this.props.pdfDocument.pdfInfo.numPages).forEach((index) => {
        const offset = this.getOffsetForPageIndex(index);

        if (offset.scrollTop < scrollTop + (clientHeight / 2)) {
          lastIndex = index;
        }
      });

      this.onPageChange(lastIndex, clientHeight);
    }
  }

  getCenterOfVisiblePage = (scrollWindowBoundary, pageScrollBoundary, pageDimension, clientDimension) => {
    const scrolledLocationOnPage = (scrollWindowBoundary - pageScrollBoundary) / this.props.scale;
    const adjustedScrolledLocationOnPage = scrolledLocationOnPage ? scrolledLocationOnPage : scrolledLocationOnPage / 2;

    const positionBasedOnPageDimension = (pageDimension + scrolledLocationOnPage - ANNOTATION_ICON_SIDE_LENGTH) / 2;
    const positionBasedOnClientDimension = adjustedScrolledLocationOnPage +
      (((clientDimension / this.props.scale) - ANNOTATION_ICON_SIDE_LENGTH) / 2);

    return Math.min(positionBasedOnPageDimension, positionBasedOnClientDimension);
  }

  handleAltC = () => {
    if (this.props.sidebarHidden) {
      this.props.togglePdfSidebar();
    }

    this.props.startPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);

    const { width, height } = this.pageDimensions(this.currentPage);
    const pagePosition = this.getOffsetForPageIndex(this.currentPage);

    const initialCommentCoordinates = {
      x: this.getCenterOfVisiblePage(this.scrollLeft, pagePosition.scrollLeft, width, this.clientWidth),
      y: this.getCenterOfVisiblePage(this.scrollTop, pagePosition.scrollTop, height, this.clientHeight)
    };

    this.props.showPlaceAnnotationIcon(this.currentPage, initialCommentCoordinates);
  }

  keyListener = (event) => {
    if (isUserEditingText() || !this.props.isVisible) {
      return;
    }

    if (event.altKey) {
      if (event.code === 'KeyC') {
        this.handleAltC();
      }
    }
  }

  displayErrorMessage = () => {
    if (!this.props.isVisible) {
      return;
    }

    const downloadUrl = `${this.props.file}?type=${this.props.documentType}&download=true`;

    // Center the status message vertically
    const style = {
      position: 'absolute',
      top: '40%',
      left: '50%',
      width: `${PDF_PAGE_WIDTH}px`,
      transform: 'translate(-50%, -50%)'
    };

    return <div style={style}>
      <StatusMessage title="Unable to load document" type="warning">
          Caseflow is experiencing technical difficulties and cannot load <strong>{this.props.documentType}</strong>.
        <br />
          You can try <a href={downloadUrl}>downloading the document</a> or try again later.
      </StatusMessage>
    </div>;
  }

  render() {
    if (this.props.loadError) {
      return <div>{this.displayErrorMessage()}</div>;
    }

    // Consider the following scenario: A user loads PDF 1, they then move to PDF 3 and
    // PDF 1 is unloaded, the pdfDocument object is cleaned up. However, before the Redux
    // state is nulled out the user moves back to PDF 1. We still can access the old destroyed
    // pdfDocument in the Redux state. So we must check that the transport is not destroyed
    // before trying to render the page.
    if (this.props.pdfDocument && !this.props.pdfDocument.transport.destroyed && this.props.isVisible) {
      return <AutoSizer>{
        ({ width, height }) => {
          if (this.clientHeight !== height) {
            _.defer(this.onPageChange, this.currentPage, height);
            this.clientHeight = height;
          }
          if (this.clientWidth !== width) {
            this.clientWidth = width;
          }

          this.columnCount = Math.min(Math.max(Math.floor(width / this.getColumnWidth()), 1),
            this.props.pdfDocument.pdfInfo.numPages);

          return <Grid
            ref={this.getGrid}
            containerStyle={{
              margin: '0 auto',
              marginTop: `${PAGE_MARGIN}px`
            }}
            estimatedRowSize={(this.props.baseHeight + PAGE_MARGIN) * this.props.scale}
            overscanRowCount={Math.floor(this.props.windowingOverscan / this.columnCount)}
            onSectionRendered={this.onSectionRendered}
            onScroll={this.onScroll}
            height={height}
            rowCount={Math.ceil(this.props.pdfDocument.pdfInfo.numPages / this.columnCount)}
            rowHeight={this.getRowHeight}
            cellRenderer={this.getPage}
            scrollToAlignment="start"
            width={width}
            columnWidth={this.getColumnWidth}
            columnCount={this.columnCount}
            scale={this.props.scale}
          />;
        }
      }
      </AutoSizer>;
    }

    return null;
  }
}

PdfFile.propTypes = {
  pdfDocument: PropTypes.object,
  setDocScrollPosition: PropTypes.func,
  scrollToComment: PropTypes.shape({
    id: PropTypes.number
  })
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPdfDocument,
    clearPdfDocument,
    resetJumpToPage,
    onScrollToComment,
    startPlacingAnnotation,
    showPlaceAnnotationIcon,
    setDocumentLoadError,
    clearDocumentLoadError,
    setDocScrollPosition,
    updateSearchIndexPage,
    updateSearchRelativeIndex
  }, dispatch)
});

const mapStateToProps = (state, props) => {
  const dimensionValues = _.filter(state.pdf.pageDimensions, (dimension) => dimension.file === props.file);
  const baseHeight = _.get(dimensionValues, [0, 'height'], PDF_PAGE_HEIGHT);
  const baseWidth = _.get(dimensionValues, [0, 'width'], PDF_PAGE_WIDTH);

  return {
    baseHeight,
    baseWidth,
    currentMatchIndex: getCurrentMatchIndex(state, props),
    matchesPerPage: getMatchesPerPageInFile(state, props),
    searchText: searchText(state, props),
    ..._.pick(state.pdfViewer, 'jumpToPageNumber', 'scrollTop'),
    ..._.pick(state.pdf, 'pageDimensions', 'scrollToComment'),
    loadError: state.pdf.documentErrors[props.file],
    pdfDocument: state.pdf.pdfDocuments[props.file],
    windowingOverscan: state.pdfViewer.windowingOverscan
  };
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
