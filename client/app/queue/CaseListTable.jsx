import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';

import CaseDetailsLink from './CaseDetailsLink';
import Table from '../components/Table';

import { DateString } from '../util/DateUtil';
import { renderAppealType } from './utils';
import COPY from '../../COPY.json';

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
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (appeal) => <React.Fragment>
        <CaseDetailsLink
          appeal={appeal}
          getLinkText={() => appeal.docketNumber} />
      </React.Fragment>
    },
    {
      header: COPY.CASE_LIST_TABLE_APPELLANT_NAME_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.appellantFullName || appeal.veteranFullName
    },
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_STATUS_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.status
    },
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: (appeal) => renderAppealType(appeal)
    },
    {
      header: COPY.CASE_LIST_TABLE_DECISION_DATE_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.decisionDate ?
        <DateString date={appeal.decisionDate} /> :
        ''
    },
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
      valueFunction: (appeal) => labelForLocation(appeal.locationCode)
    }
  ];

  render = () => <Table
    columns={this.getColumns}
    rowObjects={this.props.appeals}
    getKeyForRow={this.getKeyForRow}
    styling={this.props.styling}
  />;
}

CaseListTable.propTypes = {
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired,
  styling: PropTypes.object
};

const mapStateToProps = () => ({});

export default connect(mapStateToProps)(CaseListTable);

