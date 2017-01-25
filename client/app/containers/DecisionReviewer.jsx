import React, { PropTypes } from 'react';
import { PDFJS } from 'pdfjs-dist/web/pdf_viewer.js';
import PdfViewer from '../components/PdfViewer';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = { pdf: 0 };
    console.log('constructed');
    PDFJS.workerSrc = '../assets/dist/pdf.worker.js';
  }

  previousPdf = () => {
    this.setState({
      pdf: Math.max(this.state.pdf - 1, 0)
    });
  }

  nextPdf = () => {
    this.setState({
      pdf: Math.min(this.state.pdf + 1, this.props.pdfLinks.length - 1)
    });
  }

  componentDidMount() {
    window.addEventListener('keydown', (event) => {
      if (event.key === 'ArrowLeft') {
        previousPdf();
      }
      if (event.key === 'ArrowRight') {
        nextPdf();
      }
    });
  }

  render() {
    let { pdfLinks } = this.props;

    return (
      <div>
        <PdfViewer
          file={pdfLinks[this.state.pdf]}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf} />
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  pdfLinks: PropTypes.arrayOf(PropTypes.string).isRequired
};
