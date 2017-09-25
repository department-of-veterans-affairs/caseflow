import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { setPdfDocument, clearPdfDocument } from '../reader/actions';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

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
    console.log('mounting pdfFile', this.props.file);
    PDFJS.workerSrc = this.props.pdfWorker;

    // We have to set withCredentials to true since we're requesting the file from a
    // different domain (eFolder), and still need to pass our credentials to authenticate.
    this.loadingTask = PDFJS.getDocument({
      url: this.props.file,
      withCredentials: true
    });

    return this.loadingTask.then((pdfDocument) => {
      if (!this.loadingTask.destroyed) {
        this.loadingTask = null;
        this.pdfDocument = pdfDocument;
        this.props.setPdfDocument(this.props.file, pdfDocument);
      } else {
        pdfDocument.destroy();
      }
    }).
    catch(() => {
      this.loadingTask = null;
    });
  }

  componentWillUnmount = () => {
    console.log('unmounting pdfFile', this.props.file);
    if (this.loadingTask) {
      this.loadingTask.destroy();
      console.log('loading task', this.loadingTask);
    }
    if (this.pdfDocument) {
      this.pdfDocument.destroy();
      this.props.clearPdfDocument(this.props.file, this.pdfDocument);
    }
  }

  getPages = () => {
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
  pdfDocument: state.readerReducer.pdfDocuments[props.file]
});

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
