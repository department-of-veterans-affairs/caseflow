import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import CaseDetailsLink from './CaseDetailsLink';
import DocketTypeBadge from '../components/DocketTypeBadge';
import HearingBadge from './components/HearingBadge';
import Table from '../components/Table';
import { COLORS } from '../constants/AppConstants';
import { clearCaseListSearch } from './CaseList/CaseListActions';

import { DateString } from '../util/DateUtil';
import { renderAppealType, mostRecentHeldHearingForAppeal } from './utils';
import COPY from '../../COPY';

const currentAssigneeStyling = css({
  color: COLORS.GREEN
});

const labelForLocation = (assignedToLocation, userId) => {
  if (!assignedToLocation) {
    return '';
  }

  const regex = new RegExp(`\\b(?:BVA|VACO|VHAISA)?${assignedToLocation}\\b`);

  if (userId.match(regex) !== null) {
    return <span {...currentAssigneeStyling}>{COPY.CASE_LIST_TABLE_ASSIGNEE_IS_CURRENT_USER_LABEL}</span>;
  }

  return assignedToLocation;
};

class CaseListTable extends React.PureComponent {
  componentWillUnmount = () => this.props.clearCaseListSearch();

  getKeyForRow = (rowNumber, object) => object.id;

  getColumns = () => {
    const columns = [
      {
        header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
        valueFunction: (appeal) => {
          return <React.Fragment>
            <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />
            <CaseDetailsLink
              appeal={appeal}
              userRole={this.props.userRole}
              getLinkText={() => appeal.docketNumber} />
          </React.Fragment>;
        }
      },
      {
        header: COPY.CASE_LIST_TABLE_APPELLANT_NAME_COLUMN_TITLE,
        valueFunction: (appeal) => appeal.appellantFullName || appeal.veteranFullName
      },
      {
        header: COPY.CASE_LIST_TABLE_APPEAL_STATUS_COLUMN_TITLE,
        valueFunction: (appeal) => appeal.withdrawn === true ? 'Withdrawn' : appeal.status
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
        valueFunction: (appeal) => labelForLocation(appeal.assignedToLocation, this.props.userCssId)
      }
    ];

    const doAnyAppealsHaveHeldHearings = Boolean(
      _.find(this.props.appeals, (appeal) => mostRecentHeldHearingForAppeal(appeal))
    );

    if (doAnyAppealsHaveHeldHearings) {
      const hearingColumn = {
        valueFunction: (appeal) => {
          const mostRecentHearing = mostRecentHeldHearingForAppeal(appeal);

          return mostRecentHearing ? <HearingBadge hearing={mostRecentHearing} /> : null;
        }
      };

      columns.unshift(hearingColumn);
    }

    return columns;
  }

  render = () => {
    if (this.props.appeals.length === 0) {
      return <p>{COPY.CASE_LIST_TABLE_EMPTY_TEXT}</p>;
    }

    return <Table
      className="cf-case-list-table"
      columns={this.getColumns}
      rowObjects={this.props.appeals}
      getKeyForRow={this.getKeyForRow}
      styling={this.props.styling}
    />;
  }
}

CaseListTable.propTypes = {
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired,
  styling: PropTypes.object,
  clearCaseListSearch: PropTypes.func,
  userRole: PropTypes.string,
  userCssId: PropTypes.string
};

const mapStateToProps = (state) => ({
  userCssId: state.ui.userCssId,
  userRole: state.ui.userRole
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListTable);
