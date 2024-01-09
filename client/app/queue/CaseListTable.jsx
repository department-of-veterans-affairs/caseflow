import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { find } from 'lodash';

import CaseDetailsLink from './CaseDetailsLink';
import DocketTypeBadge from '../components/DocketTypeBadge';
import Table from '../components/Table';
import BadgeArea from 'app/components/badges/BadgeArea';
import { clearCaseListSearch } from './CaseList/CaseListActions';
import { Checkbox } from '../components/Checkbox';

import { DateString } from '../util/DateUtil';
import { statusLabel, labelForLocation, renderAppealType, mostRecentHeldHearingForAppeal } from './utils';
import COPY from '../../COPY';
import Pagination from 'app/components/Pagination/Pagination';

class CaseListTable extends React.PureComponent {

  state = { currentPage: this.props.currentPage };

  componentWillUnmount = () => this.props.clearCaseListSearch();

  getKeyForRow = (rowNumber, object) => object.id;

  getColumns = () => {
    const columns = [];

    if (this.props.showCheckboxes) {
      columns.push(
        {
          header: '',
          valueFunction: (appeal) => {
            return (
              <Checkbox
                name={`${appeal.id}`}
                id={`${appeal.id}`}
                defaultValue={this.props.taskRelatedAppealIds.includes(appeal.id)}
                hideLabel
                onChange={(checked) => this.props.checkboxOnChange(appeal.id, checked)}
              />
            );
          }
        }
      );
    }

    columns.push(
      {
        header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
        valueFunction: (appeal) => {
          return (
            <React.Fragment>
              <DocketTypeBadge name={appeal.docketName} number={appeal.docketNumber} />
              <CaseDetailsLink
                appeal={appeal}
                userRole={this.props.userRole}
                getLinkText={() => appeal.docketNumber}
                linkOpensInNewTab={this.props.linkOpensInNewTab}
              />
            </React.Fragment>
          );
        }
      },
      {
        header: COPY.CASE_LIST_TABLE_APPELLANT_NAME_COLUMN_TITLE,
        valueFunction: (appeal) => appeal.appellantFullName || appeal.veteranFullName
      },
      {
        header: COPY.CASE_LIST_TABLE_APPEAL_STATUS_COLUMN_TITLE,
        valueFunction: (appeal) => (appeal.withdrawn === true ? 'Withdrawn' : statusLabel(appeal))
      },
      {
        header: COPY.CASE_LIST_TABLE_APPEAL_TYPE_COLUMN_TITLE,
        valueFunction: (appeal) => renderAppealType(appeal)
      },
      {
        header: COPY.CASE_LIST_TABLE_APPEAL_NUMBER_ISSUES_COLUMN_TITLE,
        valueFunction: (appeal) => appeal.issueCount
      },
      {
        header: COPY.CASE_LIST_TABLE_DECISION_DATE_COLUMN_TITLE,
        valueFunction: (appeal) => (appeal.decisionDate ? <DateString date={appeal.decisionDate} /> : '')
      },
      {
        header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
        valueFunction: (appeal) => labelForLocation(appeal, this.props.userCssId)
      }
    );

    const anyAppealsHaveFnod = Boolean(
      find(this.props.appeals, (appeal) => appeal.veteranAppellantDeceased)
    );

    const anyAppealsHaveHeldHearings = Boolean(
      find(this.props.appeals, (appeal) => mostRecentHeldHearingForAppeal(appeal))
    );

    const anyAppealsHaveOvertimeStatus = Boolean(
      find(this.props.appeals, (appeal) => appeal.overtime)
    );

    const anyAppealsAreContestedClaims = Boolean(
      find(this.props.appeals, (appeal) => appeal.contestedClaim)
    );

    const anyAppealsHaveMst = Boolean(
      find(this.props.appeals, (appeal) => appeal.mst)
    );

    const anyAppealsHavePact = Boolean(
      find(this.props.appeals, (appeal) => appeal.pact)
    );

    const badgeColumn = {
      valueFunction: (appeal) => <BadgeArea appeal={appeal} />
    };

    if (anyAppealsHaveHeldHearings || anyAppealsHaveOvertimeStatus ||
        anyAppealsHaveFnod || anyAppealsAreContestedClaims || anyAppealsHaveMst || anyAppealsHavePact) {
      columns.unshift(badgeColumn);
    }

    return columns;
  };

  render = () => {
    if (this.props.appeals.length === 0) {
      return <p>{COPY.CASE_LIST_TABLE_EMPTY_TEXT}</p>;
    }

    const updatePageHandler = (idx) => {
      const newCurrentPage = idx + 1;

      this.setState({ currentPage: newCurrentPage });

      if (typeof this.props.updatePageHandlerCallback !== 'undefined') {
        this.props.updatePageHandlerCallback(newCurrentPage);
      }
    };
    const totalPages = Math.ceil(this.props.appeals.length / 5);
    const startIndex = (this.state.currentPage * 5) - 5;
    const endIndex = (this.state.currentPage * 5);

    return (
      this.props.paginate ?
        <div>
          <Pagination
            pageSize={5}
            currentPage={this.state.currentPage}
            currentCases={this.props.appeals.slice(startIndex, endIndex).length}
            totalPages={totalPages}
            totalCases={this.props.appeals.length}
            updatePage={updatePageHandler}
            table={
              <Table
                className="cf-case-list-table"
                columns={this.getColumns}
                rowObjects={this.props.appeals.slice(startIndex, endIndex)}
                getKeyForRow={this.getKeyForRow}
                styling={this.props.styling}
              />
            }
          />
        </div> :
        <Table
          className="cf-case-list-table"
          columns={this.getColumns}
          rowObjects={this.props.appeals}
          getKeyForRow={this.getKeyForRow}
          styling={this.props.styling}
        />
    );
  };
}

CaseListTable.propTypes = {
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired,
  taskRelatedAppealIds: PropTypes.array,
  showCheckboxes: PropTypes.bool,
  paginate: PropTypes.bool,
  linkOpensInNewTab: PropTypes.bool,
  checkboxOnChange: PropTypes.func,
  styling: PropTypes.object,
  clearCaseListSearch: PropTypes.func,
  userRole: PropTypes.string,
  userCssId: PropTypes.string,
  currentPage: PropTypes.number,
  updatePageHandlerCallback: PropTypes.func
};

CaseListTable.defaultProps = {
  showCheckboxes: false,
  paginate: false,
  currentPage: 1
};

const mapStateToProps = (state) => ({
  userCssId: state.ui.userCssId,
  userRole: state.ui.userRole
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      clearCaseListSearch
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseListTable);
