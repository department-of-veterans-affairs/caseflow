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
      valueFunction: (appeal) => appeal.attributes.docket_number
    },
    {
      header: 'Appellant Name',
      valueFunction: (appeal) => appeal.attributes.appellant_full_name || appeal.attributes.veteran_full_name
    },
    {
      header: 'Status',
      valueFunction: (appeal) => appeal.attributes.status
    },
    {
      header: 'Type(s)',
      valueFunction: (appeal) => renderAppealType(appeal)
    },
    {
      header: 'Decision Date',
      valueFunction: (appeal) => appeal.attributes.decision_date ? <DateString date={appeal.attributes.decision_date} /> : ''
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
