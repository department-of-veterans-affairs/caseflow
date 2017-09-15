import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { pageNumberOfPageIndex } from './utils';
import { setPdfDocument } from '../reader/actions';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

// This comes from the class .pdfViewer.singlePageView .page in _reviewer.scss.
// We need it defined here to be able to expand/contract margin between pages
// as we zoom.
const PAGE_MARGIN_BOTTOM = 25;

// These both come from _pdf_viewer.css and is the default height
// of the pages in the PDF. We need it defined here to be
// able to expand/contract the height of the pages as we zoom.
const PAGE_WIDTH = 816;
const PAGE_HEIGHT = 1056;

// Under this maximum squared distance pages are drawn, beyond it they are not.
const MAX_SQUARED_DISTANCE = 10000000;
const NUMBER_OF_NON_VISIBLE_PAGES_TO_RENDER = 2;

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.isDrawn = false;
    this.previousShouldDraw = 0;
    this.loadingTask = null;
  }

  componentDidMount = () => {
    this.loadingTask = PDFJS.getDocument({
      url: this.props.file,
      withCredentials: true
    });

    return this.loadingTask.then((pdfDocument) => {
      this.loadingTask = null;
      this.props.setPdfDocument(this.props.file, pdfDocument);
    }).
    catch(() => {
      this.loadingTask = null;
    });
  }

  componentWillUnmount = () => {
    if (this.props.pdfDocument) {
      this.props.pdfDocument.destroy();
      this.props.setPdfDocument(this.props.file, null);
    }
  }

  getPages = () => {
    if (this.props.pdfDocument) {
      return _.range(this.props.pdfDocument.pdfInfo.numPages).map((pageIndex) => <PdfPage
        scrollTop={this.props.scrollTop}
        scrollWindowCenter={this.props.scrollWindowCenter}
        documentId={this.props.documentId}
        key={pageIndex}
        file={this.props.file}
        pageIndex={pageIndex}
        isVisible={this.props.isVisible}
        scale={this.props.scale}
        getPageContainerRef={this.props.getPageContainerRef}
        pdfDocument={this.props.pdfDocument}
      />);
    } else {
      return null;
    }
  }

  render() {
    return <div>
      {this.getPages()}
      </div>;
  }
}

PdfFile.propTypes = {
  pdfDocument: PropTypes.object
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    setPdfDocument
  }, dispatch)
});

const mapStateToProps = (state, props) => ({
  pdfDocument: state.readerReducer.pdfDocuments[props.file]
});

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
