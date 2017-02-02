import React, { PropTypes } from 'react';
import Table from '../components/Table';
import Button from '../components/Button';
import DocumentLabels from '../components/DocumentLabels';
import { formatDate } from '../util/DateUtil';

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      documents: this.props.documents,
      sortByDate: 'ascending',
      sortByFilename: 'descending',
      sortByType: null
    };
  }

  sortBy = (sortType, sortDirection) => {
    let multiplier;
    if (sortDirection === 'ascending') {
      multiplier = 1;
    } else if (sortDirection === 'descending') {
      multiplier = -1;
    } else {
      return;
    }

    let documents = this.state.documents.sort((doc1, doc2) => {
      if (sortType === 'sortByDate') {
        return multiplier * (new Date(doc1.received_at) - new Date(doc2.received_at));
      }
      if (sortType === 'sortByType') {
        return multiplier * ((doc1.type < doc2.type) ? -1 : 1);
      }
      if (sortType === 'sortByFilename') {
        return multiplier * ((doc1.filename < doc2.filename) ? -1 : 1);
      }
    });
    this.setState({
      documents: documents
    });
    this.props
  }

  changeSortState = (sortType) => () => {
    let sort = this.state[sortType];
    if (sort === null) {
      sort = 'ascending';
    } else if (sort === 'ascending') {
      sort = 'descending';
    } else {
      sort = null;
    }

    let updatedState = this.state;
    updatedState[sortType] = sort;
    this.setState({
      sort
    });

    this.sortBy(sortType, sort);
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
      <div onClick={this.changeSortState('sortByDate')}>Receipt Date {getSortIcon(this.state.sortByDate)}</div>,
      <div onClick={this.changeSortState('sortByType')}>Document Type {getSortIcon(this.state.sortByType)}</div>,
      <div onClick={this.changeSortState('sortByFilename')}>Filename {getSortIcon(this.state.sortByFilename)}</div>
    ];
  }

  buildDocumentRow = (doc, index) => {
    console.log(doc + ' ' + index);
    return [
      <i style={{ color: '#23ABF6' }}
        className="fa fa-bookmark cf-pdf-bookmarks"
        aria-hidden="true"></i>,
      formatDate(doc.received_at),
      doc.type,
      <a onClick={this.props.showPdf(index)}>{doc.filename}</a>];
  }

  onLabelClick = (label) => (event) => {
    console.log(label);
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
                values={this.state.documents}
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
