import React from 'react';
import ReactDOM from 'react-dom';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { setPdfDocument, clearPdfDocument, onScrollToComment } from '../reader/Pdf/PdfActions';
import { resetJumpToPage } from '../reader/actions';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { List, CellMeasurer, AutoSizer, CellMeasurerCache } from 'react-virtualized';
import { pageIndexOfPageNumber, pageNumberOfPageIndex, rotateCoordinates } from './utils';
const PAGE_HEIGHT = 1056;

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.loadingTask = null;
    this.pdfDocument = null;
    this.list = null;
    this.startIndex = 0;
    this.stopIndex = 0;
    this.scrollTop = 0;
    this.scrollLocation = {};
    this.clientHeight = 0;
    this.currentPage = 1;
  }

  componentDidMount = () => {
    PDFJS.workerSrc = this.props.pdfWorker;

    // We have to set withCredentials to true since we're requesting the file from a
    // different domain (eFolder), and still need to pass our credentials to authenticate.
    this.loadingTask = PDFJS.getDocument({
      url: this.props.file,
      withCredentials: true
    });

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
    });
  }

  componentWillUnmount = () => {
    if (this.loadingTask) {
      this.loadingTask.destroy();
    }
    if (this.pdfDocument) {
      this.pdfDocument.destroy();
      this.props.clearPdfDocument(this.props.file, this.pdfDocument);
    }
  }

  componentWillReceiveProps(nextProps) {
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

  getPage = ({ index, key, style, parent }) => {
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
    _.get(this.pageDimensions(), ['height'], this.props.baseHeight)

  getRowHeight = ({ index }) => {
    return (this.pageHeight(index) + 25) * this.props.scale;
  }

  getList = (list) => {
    this.list = list;

    if (this.list) {
      const domNode = ReactDOM.findDOMNode(this.list);

      domNode.focus();
      this.list.recomputeRowHeights();
    }
  }

  scrollToPosition = (pageIndex, locationOnPage) => {
    this.list.scrollToPosition(this.list.getOffsetForRow({ index: pageIndex }) + locationOnPage);
  }

  componentDidUpdate = (prevProps) => {
    if (this.list) {
      this.list.recomputeRowHeights();

      if (this.scrollLocation.page) {
        this.scrollToPosition(this.scrollLocation.page, this.scrollLocation.locationOnPage);

        this.scrollLocation = {};
      }

      if (this.props.jumpToPageNumber) {
        const scrollToIndex = this.props.jumpToPageNumber ? pageIndexOfPageNumber(this.props.jumpToPageNumber) : -1

        this.list.scrollToRow(scrollToIndex);
        this.props.resetJumpToPage();
      }

      if (this.props.scrollToComment) {
        const pageIndex = pageIndexOfPageNumber(this.props.scrollToComment.page);
        const transformedY = rotateCoordinates(this.props.scrollToComment,
          this.pageDimensions(pageIndex), - this.props.rotation).y * this.props.scale;
        const scrollToY = transformedY - this.pageHeight(pageIndex) / 2;

        this.scrollToPosition(pageIndex, scrollToY);
        this.props.onScrollToComment(null);
      }
    }
  }

  onRowsRendered = ({ startIndex, stopIndex }) => {
    this.startIndex = startIndex;
    this.stopIndex = stopIndex;
  }

  onPageChange = (index, clientHeight) => {
    this.currentPage = index;
    this.props.onPageChange(pageNumberOfPageIndex(index), clientHeight / this.pageHeight(index));
  }

  onScroll = ({ clientHeight, scrollTop }) => {
    this.scrollTop = scrollTop;

    if (this.list) {
      let lastIndex = 0;

      _.range(this.startIndex, this.stopIndex + 1).forEach((index) => {
        const offset = this.list.getOffsetForRow({ index });

        if (offset < scrollTop + clientHeight / 2) {
          lastIndex = index;
        }
      });

      this.onPageChange(lastIndex, clientHeight);
    }
  }

  render() {
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
            scrollToAlignment={"start"}
            width={width}
            scale={this.props.scale}
          />;
        }
      }
      </AutoSizer>
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
    onScrollToComment
  }, dispatch)
});

const mapStateToProps = (state, props) => {
  const dimensionValues = _.filter(state.readerReducer.pageDimensions, (dimension) => dimension.file === props.file);
  const baseHeight = _.get(dimensionValues, [0, 'height'], PAGE_HEIGHT);

  return {
    pdfDocument: state.readerReducer.pdfDocuments[props.file],
    pageDimensions: state.readerReducer.pageDimensions,
    baseHeight,
    jumpToPageNumber: state.readerReducer.ui.pdf.jumpToPageNumber,
    scrollToComment: state.readerReducer.ui.pdf.scrollToComment
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
