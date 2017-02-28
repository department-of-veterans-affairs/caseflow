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
      filterBy: '',
      listView: true,
      pdf: this.props.appealDocuments.length > 1 ? null : 0,
      selectedLabels: selectedLabels,
      sortBy: 'sortByDate',
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
      pdf: Math.max(this.state.pdf - 1, 0)
    });
  }

  nextPdf = () => {
    this.setState({
      pdf: Math.min(this.state.pdf + 1, this.state.documents.length - 1)
    });
  }

  showPdf = (pdfNumber) => (event) => {
    if (event.metaKey) {
      let id = this.state.documents[pdfNumber].id;
      let filename = this.state.documents[pdfNumber].filename;
      let type = this.state.documents[pdfNumber].type;
      let receivedAt = this.state.documents[pdfNumber].received_at;
      window.open(`review/show?id=${id}&type=${type}`+
        `&received_at=${receivedAt}&filename=${filename}`, '_blank');
    } else {
      this.setState({
        pdf: pdfNumber
      });
    }
  }

  showList = () => {
    this.setState({
      pdf: null
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
    let document_id = this.state.documents[pdf].id;

    ApiUtil.patch(`/document/${document_id}/set-label`, { data })
      .then(() => {
        let unsortedDocs = [...this.state.unsortedDocuments];

        // We need to update the label in both the unsorted
        // and sorted list of documents.
        unsortedDocs.forEach((doc) => {
          if (doc.id === document_id) {
            doc.label = label;
          }
        });

        let docs = [...this.state.documents];
        docs[pdf].label = label;

        this.setState({
          documents: docs,
          unsortedDocuments: unsortedDocs
        });
      }, () => {
        // Do something with error
      });
  }

  filterDocuments = (documents) => {
    let filterBy = this.state.filterBy.toLowerCase();
    let labelsSelected = Object.keys(this.state.selectedLabels).reduce((anySelected, label) => {
      return anySelected || this.state.selectedLabels[label];
    }, false);

    let filteredDocuments = documents.filter((doc) => {
      // if there is a label selected, we filter on that.
      if (labelsSelected && !this.state.selectedLabels[doc.label]) {
        return false;
      }

      if (filterBy === '') {
        return true;
      }

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
        {this.state.pdf === null && <PdfListView
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
        {this.state.pdf !== null && <PdfViewer
          annotationStorage={this.annotationStorage}
          file={`${this.props.url}?id=` +
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
          label={documents[this.state.pdf].label}
          hideNavigation={documents.length === 1}/>}
      </div>
    );
  }
}

DecisionReviewer.propTypes = {
  annotations: PropTypes.arrayOf(PropTypes.object),
  appealDocuments: PropTypes.arrayOf(PropTypes.object).isRequired,
  pdfWorker: PropTypes.string
};
