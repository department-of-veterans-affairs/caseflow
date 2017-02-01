import React, { PropTypes } from 'react';
import Table from '../components/Table';

let PDF_LIST_TABLE_HEADERS = ['Receipt Date', 'Document Type', 'Filename'];

export default class PdfListView extends React.Component {
  constructor(props) {
    super(props);
  }

  buildPdfRow = (file) => {
    return [file, file, file];
  }

  render() {
    return <div className="cf-app-segment cf-app-segment--alt">
      <Table
        headers={PDF_LIST_TABLE_HEADERS}
        buildRowValues={this.buildPdfRow}
        values={this.props.files}
      />
    </div>;
  }
}

PdfListView.propTypes = {
  files: PropTypes.arrayOf(PropTypes.string).isRequired
};
