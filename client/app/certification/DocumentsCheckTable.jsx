import React from 'react';
import PropTypes from 'prop-types';
import FoundIcon from '../components/FoundIcon';
import NotFoundIcon from '../components/NotFoundIcon';
import Table from '../components/Table';

const found = <div style={{ display: 'inline-flex' }}><FoundIcon/>
                    <span>&emsp;Found in VBMS</span>
                 </div>;

const notFound = <div style={{ display: 'inline-flex' }}><NotFoundIcon/>
                    <span style={{ lineHeight: 1 }} className="usa-input-error-message">&emsp;Not found in VBMS</span>
                 </div>;

const documentIcon = (doc) => {
  return doc.isMatching ? found : notFound;
};

const formattedVbmsDate = (doc) => {
  return doc.isMatching ? doc.vbmsDate : '\u2014';
};

class DocumentsCheckTable extends React.Component {
  getUserColumns = () => {
    return [
      {
        header: 'Document',
        valueName: 'name'
      },
      {
        header: 'VACOLS date',
        valueName: 'vacolsDate',
        align: 'left'
      },
      {
        header: 'VBMS date',
        valueFunction: (doc) => formattedVbmsDate(doc),
        align: 'left'
      },
      {
        header: <span><span className="usa-sr-only">Status</span>Status</span>,
        valueFunction: (doc) => documentIcon(doc),
        align: 'left'
      }
    ];
  }

  render() {
    let { form9, nod, soc, ssocs } = this.props;

    return <Table
        columns={this.getUserColumns()}
        rowObjects={[form9, nod, soc].concat(ssocs)}
        caption="This table compares received dates for forms stored in VACOLS and VBMS."
        summary="Documents required for certification."
      />;
  }
}

DocumentsCheckTable.propTypes = {
  nod: PropTypes.object.isRequired,
  soc: PropTypes.object.isRequired,
  form9: PropTypes.object.isRequired,
  ssocs: PropTypes.arrayOf(PropTypes.object).isRequired
};

export default DocumentsCheckTable;
