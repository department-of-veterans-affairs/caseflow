import React, { PropTypes } from 'react';
import Table from '../components/Table';
import Button from '../components/Button';

let PDF_LIST_TABLE_HEADERS = ['', 'Receipt Date', 'Document Type', 'Filename'];

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);
  }

  buildPdfRow = (file, index) => {
    console.log(file + ' ' + index);
    return [
      'label',
      '12/19/2016',
      'NOD',
      <a onClick={this.props.showPdf(index)}>{file}</a>];
  }

  render() {
    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          <Table
            headers={PDF_LIST_TABLE_HEADERS}
            buildRowValues={this.buildPdfRow}
            values={this.props.files}
          />
        </div>
      </div>
    </div>;
  }
}

PdfListView.propTypes = {
  files: PropTypes.arrayOf(PropTypes.string).isRequired
};
