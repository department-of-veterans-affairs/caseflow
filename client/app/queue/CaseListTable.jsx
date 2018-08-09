import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { css } from 'glamor';

import CaseDetailsLink from './CaseDetailsLink';
import Table from '../components/Table';
import { COLORS } from '../constants/AppConstants';

import { DateString } from '../util/DateUtil';
import { renderLegacyAppealType } from './utils';
import COPY from '../../COPY.json';

const currentAssigneeStyling = css({
  color: COLORS.GREEN
});

const labelForLocation = (locationCode, userId) => {
  if (!locationCode) {
    return '';
  }

  const regex = new RegExp(`\\b(?:BVA|VACO|VHAISA)${locationCode}\\b`);

  if (userId.match(regex) !== null) {
    return <span {...currentAssigneeStyling}>{COPY.CASE_LIST_TABLE_ASSIGNEE_IS_CURRENT_USER_LABEL}</span>;
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
          getLinkText={() => appeal.attributes.docket_number} />
      </React.Fragment>
    },
    {
      header: COPY.CASE_LIST_TABLE_APPELLANT_NAME_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.attributes.appellant_full_name || appeal.attributes.veteran_full_name
    },
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_STATUS_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.attributes.status
    },
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
      valueFunction: (appeal) => renderLegacyAppealType({
        aod: appeal.attributes.aod,
        type: appeal.attributes.type
      })
    },
    {
      header: COPY.CASE_LIST_TABLE_DECISION_DATE_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.attributes.decision_date ?
        <DateString date={appeal.attributes.decision_date} /> :
        ''
    },
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
      valueFunction: (appeal) => labelForLocation(appeal.attributes.location_code, this.props.userCssId)
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

const mapStateToProps = (state) => ({
  userCssId: state.ui.userCssId
});

export default connect(mapStateToProps)(CaseListTable);

