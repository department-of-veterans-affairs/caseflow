import React, { PropTypes } from 'react';
import PdfViewer from '../components/PdfViewer';
import PdfListView from '../components/PdfListView';
import PDFJSAnnotate from 'pdf-annotate.js';
import AnnotationStorage from '../util/AnnotationStorage';
import ApiUtil from '../util/ApiUtil';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    let selectedLabels = {
      blue: false,
      orange: false,
      white: false,
      pink: false,
      green: false,
      yellow: false
    }

    this.state = {
      currentPdfIndex: null,
      filterBy: '',
      selectedLabels: selectedLabels,
      sortBy: 'date',
      sortDirection: 'ascending',
      unsortedDocuments: [...this.props.appealDocuments]
    };

    this.state.documents = this.filterDocuments(
      this.sortDocuments(this.state.unsortedDocuments));

    this.annotationStorage = new AnnotationStorage(this.props.annotations);
    PDFJSAnnotate.setStoreAdapter(this.annotationStorage);
  }

  previousPdf = () => {
    this.setState({
      currentPdfIndex: Math.max(this.state.currentPdfIndex - 1, 0)
    });
  }

  nextPdf = () => {
    this.setState({
      currentPdfIndex: Math.min(this.state.currentPdfIndex + 1,
        this.state.documents.length - 1)
    });
  }

  showPdf = (pdfNumber) => () => {
    this.setState({
      currentPdfIndex: pdfNumber
    });
  }

  showList = () => {
    this.setState({
      currentPdfIndex: null
    }, this.sortAndFilter);
  }

  sortAndFilter = () => {
    this.setState({
      documents: this.filterDocuments(
        this.sortDocuments(this.state.unsortedDocuments))
    });
  }

  sortDocuments = (documents) => {
    let documentCopy = [...documents];
    let multiplier;

    if (this.state.sortDirection === 'ascending') {
      multiplier = 1;
    } else if (this.state.sortDirection === 'descending') {
      multiplier = -1;
    } else {
      return;
    }

    documentCopy.sort((doc1, doc2) => {
      if (this.state.sortBy === 'date') {
        return multiplier * (new Date(doc1.received_at) - new Date(doc2.received_at));
      } else if (this.state.sortBy === 'type') {
        return multiplier * (doc1.type < doc2.type ? -1 : 1);
      } else if (this.state.sortBy === 'filename') {
        return multiplier * (doc1.filename < doc2.filename ? -1 : 1);
      }

      return 0;

    });

    return documentCopy;
  }

  changeSortState = (sortBy) => () => {
    let sortDirection = this.state.sortDirection;

    // if you click the same label then we want to
    // flip the sort type. Otherwise if you're clicking
    // a new label, we want this to sort ascending.
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
      sortBy,
      sortDirection
    }, this.sortAndFilter);
  }

  // This filters documents to those that contain the search text
  // in either the metadata (type, filename, date) or in the comments
  // on the document.
  filterDocuments = (documents) => {
    let filterBy = this.state.filterBy.toLowerCase();
    let filteredDocuments = documents.filter((doc) => {
      if (doc.type.toLowerCase().includes(filterBy)) {
        return true;
      } else if (doc.filename.toLowerCase().includes(filterBy)) {
        return true;
      } else if (doc.received_at.toLowerCase().includes(filterBy)) {
        return true;
      }

      this.annotationStorage.getAnnotationByDocumentId(doc.id).forEach((comment) => {
        if (comment.toLowerCase().includes(filterBy)) {
          return true;
        }
      });
      return false;
    });

    return filteredDocuments;
  }

  onFilter = (filterBy) => {
    this.setState({
      filterBy
    }, this.sortAndFilter);
  }

  onLabelSelected = (label) => () => {
    let selectedLabels = {...this.state.selectedLabels};
    selectedLabels[label] = !selectedLabels[label];
    this.setState({
      selectedLabels: selectedLabels
    }, this.sortAndFilter);
  }

  render() {
    let {
      documents,
      sortDirection
    } = this.state;

    return (
      <div>
        {this.state.currentPdfIndex === null && <PdfListView
          annotationStorage={this.annotationStorage}
          documents={documents}
          changeSortState={this.changeSortState}
          showPdf={this.showPdf}
          sortDirection={sortDirection}
          numberOfDocuments={this.props.appealDocuments.length}
          onFilter={this.onFilter}
          filterBy={this.state.filterBy}
          sortBy={this.state.sortBy}
          selectedLabels={this.state.selectedLabels}
          selectLabel={this.onLabelSelected} />}
        {this.state.currentPdfIndex !== null && <PdfViewer
          annotationStorage={this.annotationStorage}
          file={`review/pdf?id=` +
            `${documents[this.state.currentPdfIndex].id}`}
          id={documents[this.state.currentPdfIndex].id}
          receivedAt={documents[this.state.currentPdfIndex].received_at}
          type={documents[this.state.currentPdfIndex].type}
          name={documents[this.state.currentPdfIndex].filename}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf}
          pdfWorker={this.props.pdfWorker}
          showList={this.showList}
          pdfWorker={this.props.pdfWorker}
          setLabel={this.setLabel(this.state.currentPdfIndex)}
          label={documents[this.state.currentPdfIndex].label} />}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string
};
