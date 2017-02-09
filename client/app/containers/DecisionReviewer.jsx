import React, { PropTypes } from 'react';
import PdfViewer from '../components/PdfViewer';
import PdfListView from '../components/PdfListView';
import PDFJSAnnotate from 'pdf-annotate.js';
import AnnotationStorage from '../util/AnnotationStorage';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      documents: this.props.appealDocuments,
      sortBy: null,
      sortDirection: null,
      listView: true,
      pdf: null
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


  sortBy = (sortBy, sortDirection) => {
    let multiplier;
    if (sortDirection === 'ascending') {
      multiplier = 1;
    } else if (sortDirection === 'descending') {
      multiplier = -1;
    } else {
      return;
    }

    let documents = this.state.documents.sort((doc1, doc2) => {
      if (sortBy === 'sortByDate') {
        return multiplier * (new Date(doc1.received_at) - new Date(doc2.received_at));
      }
      if (sortBy === 'sortByType') {
        return multiplier * ((doc1.type < doc2.type) ? -1 : 1);
      }
      if (sortBy === 'sortByFilename') {
        return multiplier * ((doc1.filename < doc2.filename) ? -1 : 1);
      }
    });
    this.setState({
      documents: documents
    });
    this.props
  }

  changeSortState = (sortBy) => () => {
    let sortDirection = this.state.sortDirection;

    if (this.state.sortBy === sortBy) {
      if (sortDirection === 'ascending') {
        sortDirection = 'descending';
      } else {
        sortDirection = 'ascending';
      }
    } else {
      sortDirection = 'ascending';
    }

    this.setState({
      sortBy: sortBy,
      sortDirection: sortDirection
    });

    this.sortBy(sortBy, sortDirection);
  }

  render() {
    let { 
      documents,
      sortBy,
      sortDirection,
    } = this.state;

    return (
      <div>
        {this.state.pdf === null && <PdfListView
          annotationStorage={this.annotationStorage}
          documents={documents}
          changeSortState={this.changeSortState}
          showPdf={this.showPdf}
          sortBy={sortBy}
          sortDirection={sortDirection} />}
        {this.state.pdf !== null && <PdfViewer
          annotationStorage={this.annotationStorage}
          file={`review/pdf?vbms_document_id=` +
            `${documents[this.state.pdf].vbms_document_id}`}
          receivedAt={documents[this.state.pdf].received_at}
          type={documents[this.state.pdf].type}
          name={documents[this.state.pdf].filename}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf}
          showList={this.showList}
          pdfWorker={this.props.pdfWorker}
          id={documents[this.state.pdf].id} />}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string
};
