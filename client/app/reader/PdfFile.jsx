import React from 'react';
import PropTypes from 'prop-types';

import { connect } from 'react-redux';
import _ from 'lodash';
import { bindActionCreators } from 'redux';
import { setPdfDocument } from '../reader/actions';
import PdfPage from './PdfPage';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';

export class PdfFile extends React.PureComponent {
  constructor(props) {
    super(props);

    this.isDrawing = false;
    this.isDrawn = false;
    this.previousShouldDraw = 0;
    this.loadingTask = null;
  }

  componentDidMount = () => {
    PDFJS.workerSrc = this.props.pdfWorker;

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
    if (this.loadingTask) {
      this.loadingTask.destroy();
    }
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
    setPdfDocument
  }, dispatch)
});

const mapStateToProps = (state, props) => ({
  pdfDocument: state.readerReducer.pdfDocuments[props.file]
});

export default connect(mapStateToProps, mapDispatchToProps)(PdfFile);
