import React, { PropTypes } from 'react';
import Table from '../components/Table';
import DocumentLabels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';
import TextField from '../components/TextField';

export default class PdfListView extends React.Component {
  
  getDocumentTableHeaders = () => {
    let className;
    if (this.props.sortDirection === 'ascending') {
      className = "fa-caret-down";
    } else {
      className = "fa-caret-up";
    }
    
    let sortIcon = <i className={`fa ${className}`} aria-hidden="true"></i>;
    return [
      '',
      <div onClick={this.props.changeSortState('date')}>
        Receipt Date {this.props.sortBy === 'date' ? sortIcon : ' '}
      </div>,
      <div onClick={this.props.changeSortState('type')}>
        Document Type {this.props.sortBy === 'type' ? sortIcon : ' '}
      </div>,
      <div onClick={this.props.changeSortState('filename')}>
        Filename {this.props.sortBy === 'filename' ? sortIcon : ' '}
      </div>
    ];
  }

  buildDocumentRow = (doc, index) => {
    let numberOfComments = this.props.annotationStorage
      .getAnnotationByDocumentId(doc.id).length;

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

  onLabelClick = () => () => {
    // filtering code will go here when we have labels working
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
               onChange={this.props.onFilter}
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
  numberOfDocuments: PropTypes.number.isRequired,
  onFilter: PropTypes.func.isRequired
};
