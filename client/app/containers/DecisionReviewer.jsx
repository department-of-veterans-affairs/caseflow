import React, { PropTypes } from 'react';
import PdfViewer from '../components/PdfViewer';
import PdfListView from '../components/PdfListView';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = { pdf: 0 };
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
        this.previousPdf();
      }
      if (event.key === 'ArrowRight') {
        this.nextPdf();
      }
    });
  }

  render() {
    let { pdfLinks } = this.props;

    return (
      <div>
        <PdfListView
          files={pdfLinks} />
        {false && <PdfViewer
          file={pdfLinks[this.state.pdf]}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf} />}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  pdfLinks: PropTypes.arrayOf(PropTypes.string).isRequired
};
