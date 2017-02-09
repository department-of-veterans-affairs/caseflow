import React, { PropTypes } from 'react';
import PdfViewer from '../components/PdfViewer';
import PDFJSAnnotate from 'pdf-annotate.js';
import AnnotationStorage from '../util/AnnotationStorage';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);
    let labels = [];
    for (let index = 0; index < this.props.appealDocuments.length; index++) {
      labels[index] = {};
    }
    this.state = {
      labels: labels,
      pdf: 0
    };
    this.annotationStorage = new AnnotationStorage(this.props.annotations);
    PDFJSAnnotate.setStoreAdapter(this.annotationStorage);
  }

  previousPdf = () => {
    this.setState({
      pdf: Math.max(this.state.pdf - 1, 0)
    });
  }

  nextPdf = () => {
    this.setState({
      pdf: Math.min(this.state.pdf + 1, this.props.appealDocuments.length - 1)
    });
  }

  setLabel = (pdf) => (label) => {
    let labels = [...this.state.labels];
    labels[pdf] = label;
    this.setState({
      labels: labels
    });
  }

  componentDidMount() {
    window.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowLeft') {
        this.previousPdf();
      }
      if (event.key === 'ArrowRight') {
        this.nextPdf();
      }
    });
  }

  render() {
    let { appealDocuments } = this.props;

    return (
      <div>
        <PdfViewer
          annotationStorage={this.annotationStorage}
          file={`review/pdf?vbms_document_id=` +
            `${appealDocuments[this.state.pdf].vbms_document_id}`}
          annotations={this.state.annotations}
          id={appealDocuments[this.state.pdf].id}
          receivedAt={appealDocuments[this.state.pdf].received_at}
          type={appealDocuments[this.state.pdf].type}
          name={appealDocuments[this.state.pdf].filename}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf}
          pdfWorker={this.props.pdfWorker}
          setLabel={this.setLabel(this.state.pdf)}
          label={this.state.labels[this.state.pdf]} />
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string
};
