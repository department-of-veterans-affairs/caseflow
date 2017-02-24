import React, { PropTypes } from 'react';
import Table from '../components/Table';
import Button from '../components/Button';
import DocumentLabels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';
import TextField from '../components/TextField';

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
      numberOfComments: [],
      sortIcon: sortIcon
    };
  }

  getDocumentTableHeaders = () => {
    return [
      '',
      <div onClick={this.props.changeSortState('sortByDate')}>Receipt Date {this.props.sortBy === 'sortByDate' ? this.state.sortIcon : ' '}</div>,
      <div onClick={this.props.changeSortState('sortByType')}>Document Type {this.props.sortBy === 'sortByType' ? this.state.sortIcon : ' '}</div>,
      <div onClick={this.props.changeSortState('sortByFilename')}>Filename {this.props.sortBy === 'sortByFilename' ? this.state.sortIcon : ' '}</div>
    ];
  }

  buildDocumentRow = (doc, index) => {
    let numberOfComments = this.props.annotationStorage.getAnnotationByDocumentId(doc.id).length;
    return [
      <div><i style={{ color: '#23ABF6' }}
        className="fa fa-bookmark cf-pdf-bookmarks"
        aria-hidden="true"></i>
        <span className="fa-stack fa-3x cf-pdf-comment-indicator">
          <i className="fa fa-comment-o fa-stack-2x"></i>
          <strong className="fa-stack-1x fa-stack-text">{numberOfComments}</strong>
        </span>
      </div>,
      formatDate(doc.received_at),
      doc.type,
      <a onClick={this.props.showPdf(index)}>{doc.filename}</a>];
  }

  onLabelClick = (_label) => () => {
    // filtering code will go here when we have labels working
  }

  onFilter = (value) => {
    this.props.onFilter(value);
  }

  render() {
    return <div>
      <div className="usa-grid">
        <div className="cf-app">
          <div className="cf-app-segment cf-app-segment--alt">
            <span>
              Show only: <DocumentLabels onClick={this.onLabelClick} />
            </span>
            <span className="cf-right-side">
              Showing {`${this.props.documents.length} out of ` +
              `${this.props.numberOfDocuments}`} documents
            </span>
            <div>
              <TextField
               label="Search"
               name="Filter By"
               value={this.props.filterBy}
               onChange={this.onFilter}
              />
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
      </div>
    </div>;
  }
}

PdfListView.propTypes = {
  documents: PropTypes.arrayOf(PropTypes.object).isRequired,
  filterBy: PropTypes.string.isRequired,
  onFilter: PropTypes.func.isRequired,
  numberOfDocuments: PropTypes.number.isRequired
};
