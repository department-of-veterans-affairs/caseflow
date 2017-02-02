import React, { PropTypes } from 'react';
import Table from '../components/Table';
import Button from '../components/Button';
import { formatDate } from '../util/DateUtil';

let PDF_LIST_TABLE_HEADERS = ['', 'Receipt Date', 'Document Type', 'Filename'];

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);
  }

  buildDocumentRow = (doc, index) => {
    console.log(doc + ' ' + index);
    return [
      'label',
      formatDate(doc.received_at),
      doc.type,
      <a onClick={this.props.showPdf(index)}>{doc.filename}</a>];
  }

  render() {
    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <Table
            headers={PDF_LIST_TABLE_HEADERS}
            buildRowValues={this.buildDocumentRow}
            values={this.props.documents}
          />
        </div>
      </div>
    </div>;
  }
}

PdfListView.propTypes = {
  files: PropTypes.arrayOf(PropTypes.string).isRequired
};
