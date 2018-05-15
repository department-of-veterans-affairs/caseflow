import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import Table from '../components/Table';
import { DateString } from '../util/DateUtil';
import { renderAppealType } from './utils';
import COPY from '../../../COPY.json';

import { setActiveAppeal } from './CaseDetail/CaseDetailActions';
import { setBreadcrumbs } from './uiReducer/uiActions';

const labelForLocation = (locationCode) => {
  if (!locationCode) {
    return '';
  }

  return locationCode;
};

class CaseListTable extends React.PureComponent {
  getKeyForRow = (rowNumber, object) => object.id;

  setActiveAppealAndBreadcrumbs = (appeal) => {
    this.props.setActiveAppeal(appeal);
    this.props.setBreadcrumbs({
      breadcrumb: sprintf(COPY.BACK_TO_SEARCH_RESULTS_LINK_LABEL, appeal.attributes.veteran_full_name),
      path: window.location.pathname
    });
  }

  getColumns = () => [
    {
      header: COPY.CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE,
      valueFunction: (appeal) => <span>
        <Link
          to={`/queue/appeals/${appeal.attributes.vacols_id}`}
          onClick={() => this.setActiveAppealAndBreadcrumbs(appeal)}
        >
          {appeal.attributes.docket_number}
        </Link>
      </span>
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
      valueFunction: (appeal) => renderAppealType(appeal)
    },
    {
      header: COPY.CASE_LIST_TABLE_DECISION_DATE_COLUMN_TITLE,
      valueFunction: (appeal) => appeal.attributes.decision_date ?
        <DateString date={appeal.attributes.decision_date} /> :
        ''
    },
    {
      header: COPY.CASE_LIST_TABLE_APPEAL_LOCATION_COLUMN_TITLE,
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

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setActiveAppeal,
  setBreadcrumbs
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListTable);

