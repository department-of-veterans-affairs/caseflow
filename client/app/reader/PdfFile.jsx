import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { resetJumpToPage } from '../reader/PdfViewer/PdfViewerActions';
import StatusMessage from '../components/StatusMessage';
import { PDF_PAGE_WIDTH, PDF_PAGE_HEIGHT } from './constants';
import { setPdfDocument, clearPdfDocument, onScrollToComment, setDocumentLoadError, clearDocumentLoadError }
  from '../reader/Pdf/PdfActions';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { List, AutoSizer } from 'react-virtualized';
import { isUserEditingText, pageIndexOfPageNumber, pageNumberOfPageIndex, rotateCoordinates } from './utils';
import { startPlacingAnnotation, showPlaceAnnotationIcon }
  from '../reader/PdfViewer/AnnotationActions';
import { INTERACTION_TYPES } from '../reader/analytics';
import { ANNOTATION_ICON_SIDE_LENGTH } from '../reader/constants';

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.loadingTask = null;
    this.pdfDocument = null;
    this.list = null;
    this.startIndex = 0;
    this.scrollTop = 0;
    this.scrollLocation = {};
    this.clientHeight = 0;
    this.currentPage = 0;
  }

  componentDidMount = () => {
    PDFJS.workerSrc = this.props.pdfWorker;

    // We have to set withCredentials to true since we're requesting the file from a
    // different domain (eFolder), and still need to pass our credentials to authenticate.
    this.loadingTask = PDFJS.getDocument({
      url: this.props.file,
      withCredentials: true
    });

    window.addEventListener('keydown', this.keyListener);

    this.props.clearDocumentLoadError(this.props.file);

    return this.loadingTask.then((pdfDocument) => {
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

    if (this.list && nextProps.scale !== this.props.scale) {
      // Set the scroll location based on the current page and where you
      // are on that page scaled by the zoom factor.
      const zoomFactor = nextProps.scale / this.props.scale;
      const nonZoomedLocation = (this.scrollTop - this.list.getOffsetForRow({ index: this.startIndex }));

      this.scrollLocation = {
        page: this.startIndex,
        locationOnPage: nonZoomedLocation * zoomFactor
      };
    }
  }

  getPage = ({ index, key, style }) => {
    return <div key={key} style={style}>
      <PdfPage
        scrollTop={this.props.scrollTop}
        scrollWindowCenter={this.props.scrollWindowCenter}
        documentId={this.props.documentId}
        file={this.props.file}
        pageIndex={index}
        isVisible={this.props.isVisible}
        scale={this.props.scale}
        pdfDocument={this.props.pdfDocument}
      />
    </div>;
  }

  pageDimensions = (index) => this.props.pageDimensions[`${this.props.file}-${index}`]

  pageHeight = (index) =>
    _.get(this.pageDimensions(index), ['height'], this.props.baseHeight)

  getRowHeight = ({ index }) => {
    return (this.pageHeight(index) + 25) * this.props.scale;
  }

  getList = (list) => {
    this.list = list;

    if (this.list) {
      // eslint-disable-next-line react/no-find-dom-node
      const domNode = ReactDOM.findDOMNode(this.list);

      domNode.focus();
      this.list.recomputeRowHeights();
    }
  }

  scrollToPosition = (pageIndex, locationOnPage) => {
    const position = this.list.getOffsetForRow({ index: pageIndex }) + locationOnPage;

    this.list.scrollToPosition(Math.max(position, 0));
  }

  jumpToPage = () => {
    // We want to jump to the page, after the react virtualized has initialized the scroll window.
    if (this.props.jumpToPageNumber && this.clientHeight > 0) {
      const scrollToIndex = this.props.jumpToPageNumber ? pageIndexOfPageNumber(this.props.jumpToPageNumber) : -1;

      this.list.scrollToRow(scrollToIndex);
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

  componentDidUpdate = () => {
    if (this.list && this.props.isVisible) {
      this.list.recomputeRowHeights();
      this.scrollWhenFinishedZooming();
      this.jumpToPage();
      this.jumpToComment();
    }
  }

  onRowsRendered = ({ startIndex }) => {
    this.startIndex = startIndex;
  }

  onPageChange = (index, clientHeight) => {
    this.currentPage = index;
    this.props.onPageChange(pageNumberOfPageIndex(index), clientHeight / this.pageHeight(index));
  }

  onScroll = ({ clientHeight, scrollTop }) => {
    this.scrollTop = scrollTop;

    if (this.list) {
      let lastIndex = 0;

      _.range(0, this.props.pdfDocument.pdfInfo.numPages).forEach((index) => {
        const offset = this.list.getOffsetForRow({ index });

        if (offset < scrollTop + (clientHeight / 2)) {
          lastIndex = index;
        }
      });

      this.onPageChange(lastIndex, clientHeight);
    }
  }

  handleAltC = () => {
    if (this.props.sidebarHidden) {
      this.props.togglePdfSidebar();
    }

    this.props.startPlacingAnnotation(INTERACTION_TYPES.KEYBOARD_SHORTCUT);

    const { width, height } = this.pageDimensions(this.currentPage);
    const scrolledLocationOnPage = Math.max(0, this.scrollTop - this.list.getOffsetForRow({ index: this.currentPage }));

    const initialCommentCoordinates = {
      x: ((width - ANNOTATION_ICON_SIDE_LENGTH) / 2) / this.props.scale,
      y: ((scrolledLocationOnPage + height - ANNOTATION_ICON_SIDE_LENGTH) / 2) / this.props.scale
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
            this.onPageChange(this.currentPage, height);
            this.clientHeight = height;
          }

          return <List
            ref={this.getList}
            onRowsRendered={this.onRowsRendered}
            onScroll={this.onScroll}
            height={height}
            rowCount={this.props.pdfDocument.pdfInfo.numPages}
            rowHeight={this.getRowHeight}
            rowRenderer={this.getPage}
            scrollToAlignment={'start'}
            width={width}
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
  pdfDocument: PropTypes.object
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
    clearDocumentLoadError
  }, dispatch)
});

const mapStateToProps = (state, props) => {
  const dimensionValues = _.filter(state.readerReducer.pageDimensions, (dimension) => dimension.file === props.file);
  const baseHeight = _.get(dimensionValues, [0, 'height'], PDF_PAGE_HEIGHT);

  return {
    pdfDocument: state.readerReducer.pdfDocuments[props.file],
    pageDimensions: state.readerReducer.pageDimensions,
    baseHeight,
    jumpToPageNumber: state.readerReducer.ui.pdf.jumpToPageNumber,
    scrollToComment: state.readerReducer.ui.pdf.scrollToComment,
    loadError: state.readerReducer.documentErrors[props.file]
  };
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
