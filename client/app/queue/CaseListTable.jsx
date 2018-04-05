import React from 'react';
import PropTypes from 'prop-types';

import Table from '../components/Table';
import { renderAppealType } from './utils';
import { DateString } from '../util/DateUtil';

export default class CaseListTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getColumns = () => [
    {
      header: 'Docket Number',
      valueFunction: (appeal) => appeal.docket_number
    },
    {
      header: 'Appellant Name',
      valueFunction: (appeal) => appeal.appellant_full_name || appeal.veteran_full_name
    },
    {
      header: 'Status',
      valueFunction: (appeal) => appeal.status
    },
    {
      header: 'Type(s)',
      valueFunction: (appeal) => 'TYPE GOES HERE' // renderAppealType(appeal) // TODO: I don't think this will work until we put "attributes" back
    },
    {
      header: 'Decision Date',
      valueFunction: (appeal) => appeal.decision_date ? <DateString date={appeal.decision_date} /> : ''
    },
    {
      header: 'Assigned To',
      valueFunction: (appeal) => '1989'
    }
  ];

  render = () => <Table
    columns={this.getColumns}
    rowObjects={this.props.appeals}
    getKeyForRow={this.getKeyForRow}
  />;
}

CaseListTable.propTypes = {
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired
};
