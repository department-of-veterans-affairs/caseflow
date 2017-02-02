import React, { PropTypes } from 'react';
import PdfViewer from '../components/PdfViewer';
import PdfListView from '../components/PdfListView';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      documents: this.props.appealDocuments
      listView: true,
      pdf: null
    };
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
        this.previousPdf();
      }
      if (event.key === 'ArrowRight') {
        this.nextPdf();
      }
    });
  }

  showPdf = (pdfNumber) => () => {
    this.setState({
      pdf: pdfNumber
    })
  }

  showList = () => {
    this.setState({
      pdf: null
    });
  }

  setDocuments = (documents) => {
    this.setState({
      documents: documents
    });
  }

  render() {
    let { documents } = this.state;

    return (
      <div>
        {this.state.pdf === null && <PdfListView
          documents={this.state.appeal.documents}
          setDocuments={this.setDocuments}
          showPdf={this.showPdf} />}
        {this.state.pdf !== null && <PdfViewer
          file={`review/pdf?document_id=${documents[this.state.pdf].document_id}`}
          receivedAt={documents[this.state.pdf].received_at}
          type={documents[this.state.pdf].type}
          name={documents[this.state.pdf].filename}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf}
          showList={this.showList} />}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired
};
