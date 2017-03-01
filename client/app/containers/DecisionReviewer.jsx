import React, { PropTypes } from 'react';
import PdfViewer from '../components/PdfViewer';
import PdfListView from '../components/PdfListView';
import PDFJSAnnotate from 'pdf-annotate.js';
import AnnotationStorage from '../util/AnnotationStorage';
import ApiUtil from '../util/ApiUtil';
import StringUtil from '../util/StringUtil';

export default class DecisionReviewer extends React.Component {
  constructor(props) {
    super(props);

    let selectedLabels = {
      decisions: false,
      layperson: false,
      privateMedical: false,
      procedural: false,
      vaMedial: false,
      veteranSubmitted: false
    };

    this.state = {
      currentPdfIndex: null,
      filterBy: '',
      selectedLabels,
      sortBy: 'date',
      sortDirection: 'ascending',
      unsortedDocuments: this.props.appealDocuments.map((doc) => {
        doc.label = doc.label ? StringUtil.snakeCaseToCamelCase(doc.label) : null;

        return doc;
      })
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
    let labelsSelected = Object.keys(this.state.selectedLabels).
      reduce((anySelected, label) =>
        anySelected || this.state.selectedLabels[label], false);

    let filteredDocuments = documents.filter((doc) => {
      // if there is a label selected, we filter on that.
      if (labelsSelected && !this.state.selectedLabels[doc.label]) {
        return false;
      }

      if (doc.type.toLowerCase().includes(filterBy)) {
        return true;
      } else if (doc.filename.toLowerCase().includes(filterBy)) {
        return true;
      } else if (doc.received_at.toLowerCase().includes(filterBy)) {
        return true;
      }

      this.annotationStorage.getAnnotationByDocumentId(doc.id).forEach((annotation) => {
        if (annotation.comment.toLowerCase().includes(filterBy)) {
          return true;
        }
      });

      return false;
    });

    return filteredDocuments;
  }

  setLabel = (pdfIndex) => (label) => {
    let data = { label: StringUtil.camelCaseToSnakeCase(label) };
    let documentId = this.state.documents[pdfIndex].id;

    ApiUtil.patch(`/document/${documentId}/set-label`, { data }).
      then(() => {
        let unsortedDocs = [...this.state.unsortedDocuments];

        // We need to update the label in both the unsorted
        // and sorted list of documents. PdfIndex refers to the
        // sorted list. For the unsorted list, we need to look
        // it up by documentId.
        unsortedDocs.forEach((doc) => {
          if (doc.id === documentId) {
            doc.label = label;
          }
        });

        let docs = [...this.state.documents];

        docs[pdfIndex].label = label;

        this.setState({
          documents: docs,
          unsortedDocuments: unsortedDocs
        });
      }, () => {

        /* eslint-disable no-console */
        console.log('Error setting label');

        /* eslint-enable no-console */
      });
  }

  onFilter = (filterBy) => {
    this.setState({
      filterBy
    }, this.sortAndFilter);
  }

  onLabelSelected = (label) => () => {
    let selectedLabels = { ...this.state.selectedLabels };

    selectedLabels[label] = !selectedLabels[label];
    this.setState({
      selectedLabels
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
