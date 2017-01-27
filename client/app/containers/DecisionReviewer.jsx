import React, { PropTypes } from 'react';

import PdfViewer from '../components/PdfViewer';

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
      pdf: Math.min(this.state.pdf + 1, this.props.appealDocuments.length - 1)
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
    let { appealDocuments } = this.props;

    return (
      <div>
        <PdfViewer
          file={`http://localhost:3000/decision/review/pdf?document_id=${appealDocuments[this.state.pdf].document_id}`}
          receivedAt={appealDocuments[this.state.pdf].received_at}
          type={appealDocuments[this.state.pdf].type}
          name={appealDocuments[this.state.pdf].filename}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf} />
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired
};
