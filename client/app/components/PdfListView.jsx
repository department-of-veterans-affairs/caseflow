import React, { PropTypes } from 'react';
import Table from '../components/Table';
import Button from '../components/Button';
import DocumentLabels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';
import PDFJSAnnotate from 'pdf-annotate.js';

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      numberOfComments: []
    };
  }

  getDocumentTableHeaders = () => {
    let getSortIcon = (sort) => {
      if (sort === 'ascending') {
        return <i className="fa fa-caret-down" aria-hidden="true"></i>; 
      } else if (sort === 'descending') {
        return <i className="fa fa-caret-up" aria-hidden="true"></i>; 
      }
      return;
    }

    return [
      '',
      <div onClick={this.props.changeSortState('sortByDate')}>Receipt Date {getSortIcon(this.props.sortByDate)}</div>,
      <div onClick={this.props.changeSortState('sortByType')}>Document Type {getSortIcon(this.props.sortByType)}</div>,
      <div onClick={this.props.changeSortState('sortByFilename')}>Filename {getSortIcon(this.props.sortByFilename)}</div>
    ];
  }

  buildDocumentRow = (doc, index) => {
    return [
      <div><i style={{ color: '#23ABF6' }}
        className="fa fa-bookmark cf-pdf-bookmarks"
        aria-hidden="true"></i>
        <span className="fa-stack fa-3x cf-pdf-comment-indicator">
          <i className="fa fa-comment-o fa-stack-2x"></i>
          <strong className="fa-stack-1x fa-stack-text">{this.state.numberOfComments[index]}</strong>
        </span>
      </div>,
      formatDate(doc.received_at),
      doc.type,
      <a onClick={this.props.showPdf(index)}>{doc.filename}</a>];
  }

  onLabelClick = (label) => (event) => {
    console.log(label);
  }

  componentDidMount = () => {
    let storeAdapter = PDFJSAnnotate.getStoreAdapter();
    
    this.props.documents.forEach((doc, index) => {
      let numberOfComments = this.state.numberOfComments;
      numberOfComments[index] = index;
      this.setState({
        numberOfComments: numberOfComments
      });
    });
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
              Showing {this.props.documents.length} documents
            </span>
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
  documents: PropTypes.arrayOf(PropTypes.object).isRequired
};
