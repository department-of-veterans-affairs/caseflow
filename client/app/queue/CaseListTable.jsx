import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import Table from '../components/Table';
import { DateString } from '../util/DateUtil';
import { renderAppealType } from './utils';

import { setActiveAppeal } from './CaseDetail/CaseDetailActions';

const labelForLocation = (locationCode) => {
  if (!locationCode) {
    return '';
  }

  return locationCode;
};

class CaseListTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  getColumns = () => [
    {
      header: 'Docket Number',
      valueFunction: (appeal) => <span>
        <Link to={`/queue/appeals/${appeal.attributes.vacols_id}`} onClick={() => this.props.setActiveAppeal(appeal)}>
          {appeal.attributes.docket_number}
        </Link>
      </span>
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
      valueFunction: (appeal) => appeal.attributes.decision_date ?
        <DateString date={appeal.attributes.decision_date} /> :
        ''
    },
    {
      header: 'Assigned To',
      valueFunction: (appeal) => labelForLocation(appeal.attributes.location_code)
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

const mapStateToProps = () => ({});

const mapDispatchToProps = (dispatch) => bindActionCreators({ setActiveAppeal }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListTable);

