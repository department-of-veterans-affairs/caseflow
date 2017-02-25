import React, { PropTypes } from 'react';
import Table from '../components/Table';
import DocumentLabels, * as Labels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';
import TextField from '../components/TextField';
import SearchBar from '../components/SearchBar';

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);

    let sortIcon;

    if (this.props.sortDirection === 'ascending') {
      sortIcon = <i className="fa fa-caret-down" aria-hidden="true"></i>;
    } else {
      sortIcon = <i className="fa fa-caret-up" aria-hidden="true"></i>;
    }

    this.state = {
      selectedLabels: [],
      sortIcon
    };
  }

  getDocumentTableHeaders = () => [
    '',
    '',
    <div onClick={this.props.changeSortState('sortByDate')}>
      Receipt Date {this.props.sortBy === 'sortByDate' ? this.state.sortIcon : ' '}
    </div>,
    <div onClick={this.props.changeSortState('sortByType')}>
      Document Type {this.props.sortBy === 'sortByType' ? this.state.sortIcon : ' '}
    </div>,
    <div onClick={this.props.changeSortState('sortByFilename')}>
      Filename {this.props.sortBy === 'sortByFilename' ? this.state.sortIcon : ' '}
    </div>
  ]

  buildDocumentRow = (doc, index) => {
    let numberOfComments = this.props.annotationStorage
      .getAnnotationByDocumentId(doc.id).length;

    return [
      <div>
        { doc.label && <i style={{ color: Labels.LABEL_COLOR_MAPPING[doc.label] }}
        className="fa fa-bookmark cf-pdf-bookmarks"
        aria-hidden="true"></i> }
      </div>,
      <span className="fa-stack fa-3x cf-pdf-comment-indicator">
        <i className="fa fa-comment-o fa-stack-2x"></i>
        <strong className="fa-stack-1x fa-stack-text">{numberOfComments}</strong>
      </span>,
      formatDate(doc.received_at),
      doc.type,
      <a onClick={this.props.showPdf(index)}>{doc.filename}</a>];
  }

  onFilter = (value) => {
    this.props.onFilter(value);
  }

  render() {
    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <div className="usa-grid-full">
            <div className="usa-width-one-third">
              <SearchBar onChange={this.props.onFilter} value={this.props.filterBy} />
            </div>
            <div className="usa-width-one-third">
              <span>
                Show only:
                <DocumentLabels
                  onClick={this.props.selectLabel}
                  selectedLabels={this.props.selectedLabels} />
              </span>
            </div>
            <div className="usa-width-one-third">
              <span className="cf-right-side">
                Showing {`${this.props.documents.length} out of ` +
                `${this.props.numberOfDocuments}`} documents
              </span>
            </div>
          </div>
          <div>
            <Table
              headers={this.getDocumentTableHeaders()}
              buildRowValues={this.buildDocumentRow}
              values={this.props.documents}
            />
          </div>
        </div>
      </div>
    </div>;
  }
}

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  filterBy: PropTypes.string.isRequired,
  numberOfDocuments: PropTypes.number.isRequired,
  onFilter: PropTypes.func.isRequired
};
