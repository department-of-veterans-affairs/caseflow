import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { setPdfDocument, clearPdfDocument } from '../reader/actions';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { List, CellMeasurer, AutoSizer } from 'react-virtualized';

const PAGE_HEIGHT = 1056;

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.isDrawn = false;
    this.previousShouldDraw = 0;
    this.loadingTask = null;
    this.pdfDocument = null;
    this.list = null;
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

  getPage = ({ index, key, style }) => {
    return <div style={style} key={key}>
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
    // return <div key={key} , background: '#FFFFFF'}}></div>;
  }

  getRowHeight = ({ index }) => {
    return (_.get(this.props.pages, [index, 'dimensions', 'height'], PAGE_HEIGHT) + 25) * this.props.scale
  }

  getList = (list) => this.list = list

  componentDidUpdate = () => {
    if (this.list) {
      console.log(this.list);
      this.list.recomputeRowHeights();
    }
  }

  render() {
    // Consider the following scenario: A user loads PDF 1, they then move to PDF 3 and
    // PDF 1 is unloaded, the pdfDocument object is cleaned up. However, before the Redux
    // state is nulled out the user moves back to PDF 1. We still can access the old destroyed
    // pdfDocument in the Redux state. So we must check that the transport is not destroyed
    // before trying to render the page.

    // ({ index, isScrolling  }) => ({ width: 1000, height: 1000, x: width/2 - 250, y: 1000 * index })
    if (this.props.pdfDocument && !this.props.pdfDocument.transport.destroyed && this.props.isVisible) {
      return <AutoSizer>{({ width, height }) =>
          <List
            ref={this.getList}
            estimatedRowSize={780}
            height={height}
            rowCount={this.props.pdfDocument.pdfInfo.numPages}
            rowHeight={this.getRowHeight}
            rowRenderer={this.getPage}
            width={width}
          />}
      </AutoSizer>
    }


    // <Collection
    //       cellCount={this.props.pdfDocument.pdfInfo.numPages}
    //       cellRenderer={this.getPage}
    //       cellSizeAndPositionGetter={this.cellSizeAndPosition}
    //       height={height}
    //       width={width}
    //     />

    return null;
  }
}

PdfFile.propTypes = {
  pdfDocument: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPdfDocument,
    clearPdfDocument
  }, dispatch)
});

const mapStateToProps = (state, props) => {
  const pages = _.get(state.readerReducer.pages, [props.file]) || {};

  return {
    pdfDocument: state.readerReducer.pdfDocuments[props.file],
    pages
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
