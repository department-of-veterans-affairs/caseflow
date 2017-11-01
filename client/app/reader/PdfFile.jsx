import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { setPdfDocument, clearPdfDocument } from '../reader/Pdf/PdfActions';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import { getCurrentMatchIndex } from './selectors';

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.isDrawn = false;
    this.previousShouldDraw = 0;
    this.loadingTask = null;
    this.pdfDocument = null;
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
    if (this.marks) {
      this.marks = [];
    }
  }

  getPages = () => {
    // Consider the following scenario: A user loads PDF 1, they then move to PDF 3 and
    // PDF 1 is unloaded, the pdfDocument object is cleaned up. However, before the Redux
    // state is nulled out the user moves back to PDF 1. We still can access the old destroyed
    // pdfDocument in the Redux state. So we must check that the transport is not destroyed
    // before trying to render the page.
    if (this.props.pdfDocument && !this.props.pdfDocument.transport.destroyed) {
      return _.range(this.props.pdfDocument.pdfInfo.numPages).map((pageIndex) => <PdfPage
        scrollTop={this.props.scrollTop}
        scrollWindowCenter={this.props.scrollWindowCenter}
        documentId={this.props.documentId}
        key={pageIndex}
        file={this.props.file}
        pageIndex={pageIndex}
        isVisible={this.props.isVisible}
        scale={this.props.scale}
        pdfDocument={this.props.pdfDocument}
      />);
    }

    return null;
  }

  render() {
    return <div>
      {this.getPages()}
    </div>;
  }

  componentDidUpdate = () => {
    if (!this.marks) {
      this.marks = document.getElementsByTagName('mark');
    }

    _(this.marks).
      filter((mark) => {
        return mark.classList.contains('highlighted');
      }).
      each((mark) => {
        mark.classList.remove('highlighted');
      });

    const selectedMark = this.marks[this.props.currentMatchIndex];

    if (selectedMark) {
      selectedMark.classList.add('highlighted');

      // mark parent elements are absolutely-positioned divs
      // todo: selectedMark.parentElement.top is relative to page, doesn't consider stacked pages
      // let scrollTop = parseInt(selectedMark.parentElement.style.top, 10);

      // if scrolling to < 100px, just scroll to top
      // scrollTop = scrollTop < 100 ? 0 : scrollTop;
      // this.props.scrollWindow.scrollTo(0, scrollTop);
    }
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

const mapStateToProps = (state, props) => ({
  pdfDocument: state.readerReducer.pdfDocuments[props.file],
  currentMatchIndex: getCurrentMatchIndex(state, props)
});

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
