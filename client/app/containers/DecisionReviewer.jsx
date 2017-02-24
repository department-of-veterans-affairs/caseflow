import React, { PropTypes } from 'react';
import PdfViewer from '../components/PdfViewer';
import PdfListView from '../components/PdfListView';
import PDFJSAnnotate from 'pdf-annotate.js';
import AnnotationStorage from '../util/AnnotationStorage';
import ApiUtil from '../util/ApiUtil';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    let labels = [];
    this.props.appealDocuments.forEach((doc) => {
      labels.push(doc.label);
    });
    this.state = {
      
      pdf: 0
    };

    this.state = {
      filterBy: '',
      labels: labels,
      listView: true,
      pdf: null,
      sortBy: 'sortByDate',
      sortDirection: 'ascending'
    };

    this.state.documents = this.filterDocuments(
      this.sortDocuments(this.props.appealDocuments));

>>>>>>> mdbenjam-kavi-crazy
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
      pdf: Math.min(this.state.pdf + 1, this.state.documents.length - 1)
    });
  }

  showPdf = (pdfNumber) => () => {
    this.setState({
      pdf: pdfNumber
    });
  }

  showList = () => {
    this.setState({
      pdf: null
    });
  }

  sortAndFilter = () => {
    this.setState({
      documents: this.filterDocuments(
        this.sortDocuments(this.props.appealDocuments))
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
      if (this.state.sortBy === 'sortByDate') {
        return multiplier * (new Date(doc1.received_at) - new Date(doc2.received_at));
      } else if (this.state.sortBy === 'sortByType') {
        return multiplier * (doc1.type < doc2.type ? -1 : 1);
      } else if (this.state.sortBy === 'sortByFilename') {
        return multiplier * (doc1.filename < doc2.filename ? -1 : 1);
      }

      return 0;

    });

    return documentCopy;
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
      sortBy,
      sortDirection
    }, this.sortAndFilter);
  }

  setLabel = (pdf) => (label) => {
    let data = {label: label};
    let document_id = this.props.appealDocuments[this.state.pdf].id;

    ApiUtil.patch(`/document/${document_id}/set-label`, { data })
      .then(() => {
        let labels = [...this.state.labels];
        labels[pdf] = label;

        this.setState({
          labels: labels
        });
      }, () => {
        // Do something with error
      });
  }

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
      let comments = this.annotationStorage.getAnnotationByDocumentId(doc.id).
        reduce((combined, comment) =>
          `${combined} ${comment.comment.toLowerCase()}`, '');

      if (comments.includes(filterBy)) {
        return true;
      }
      return false;
    });

    return filteredDocuments;
  }

  onFilter = (filterBy) => {
    this.setState({
      filterBy
    }, this.sortAndFilter);
  }

  render() {
    let {
      documents,
      sortDirection
    } = this.state;

    return (
      <div>
        {this.state.pdf === null && <PdfListView
          annotationStorage={this.annotationStorage}
          documents={documents}
          changeSortState={this.changeSortState}
          showPdf={this.showPdf}
          sortDirection={sortDirection}
          numberOfDocuments={this.props.appealDocuments.length}
          onFilter={this.onFilter}
          filterBy={this.state.filterBy}
          sortBy={this.state.sortBy} />}
        {this.state.pdf !== null && <PdfViewer
          annotationStorage={this.annotationStorage}
          file={`review/pdf?id=` +
            `${documents[this.state.pdf].id}`}
          annotations={this.state.annotations}
          id={documents[this.state.pdf].id}
          receivedAt={documents[this.state.pdf].received_at}
          type={documents[this.state.pdf].type}
          name={documents[this.state.pdf].filename}
          previousPdf={this.previousPdf}
          nextPdf={this.nextPdf}
          pdfWorker={this.props.pdfWorker}
          showList={this.showList}
          pdfWorker={this.props.pdfWorker}
          setLabel={this.setLabel(this.state.pdf)}
          label={this.state.labels[this.state.pdf]} />}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string
};
