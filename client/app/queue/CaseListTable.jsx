import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import CaseDetailsLink from './CaseDetailsLink';
import DocketTypeBadge from './components/DocketTypeBadge';
import Table from '../components/Table';
import { COLORS } from '../constants/AppConstants';
import { clearCaseListSearch } from './CaseList/CaseListActions';

import { DateString } from '../util/DateUtil';
import { renderAppealType } from './utils';
import COPY from '../../COPY.json';

const currentAssigneeStyling = css({
  color: COLORS.GREEN
});

const getLocationCode = (locationCode, userId) => {
  if (locationCode === userId) {
    return <span {...currentAssigneeStyling}>{COPY.CASE_LIST_TABLE_ASSIGNEE_IS_CURRENT_USER_LABEL}</span>;
  }

  return locationCode;
};

const labelForLocation = (locationCode, userId) => {
  debugger;
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
  componentWillUnmount = () => this.props.clearCaseListSearch();

  getKeyForRow = (rowNumber, object) => object.id;

  getColumns = () => [
    {
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (appeal) => <React.Fragment>
        <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />
        <CaseDetailsLink
          appeal={appeal}
          userRole={this.props.userRole}
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
    // TODO: use some other field for AMA appeals — legacy appeals use location_code
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
      // valueFunction: (appeal) => labelForLocation(appeal.locationCode, this.props.userCssId)
      valueFunction: (appeal) => getLocationCode(appeal.locationCode, this.props.userCssId)
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
  userCssId: state.ui.userCssId,
  userRole: state.ui.userRole
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListTable);
