import React from 'react';
import PropTypes from 'prop-types';
import FoundIcon from '../components/FoundIcon';
import NotFoundIcon from '../components/NotFoundIcon';
import Table from '../components/Table';

const documentIcon = (doc) => {
  return doc.isMatching ? <FoundIcon/> : <NotFoundIcon/>;
};

const formattedVbmsDate = (doc) => {
  return doc.isMatching ? doc.vbmsDate : 'Not Found';
};

class DocumentsCheckTable extends React.Component {
  getUserColumns = () => {
    return [
      {
        header: <span><span className="usa-sr-only">Status</span>Found in VBMS?</span>,
        valueFunction: (doc) => documentIcon(doc),
        align: 'center'
      },
      {
        header: 'Document',
        valueName: 'name'
      },
      {
        header: 'VACOLS date',
        valueName: 'vacolsDate',
        align: 'center'
      },
      {
        header: 'VBMS date',
        valueFunction: (doc) => formattedVbmsDate(doc),
        align: 'center'
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
