import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Table from '../components/Table';
import { clearCaseListSearch } from './CaseList/CaseListActions';

import { DateString } from '../util/DateUtil';
import COPY from '../../COPY.json';

class CaseListTable extends React.PureComponent {
  componentWillUnmount = () => this.props.clearCaseListSearch();

  getKeyForRow = (rowNumber, object) => object.id;

  getColumns = () => [
    {
      header: COPY.OTHER_REVIEWS_TABLE_EP_CODE_COLUMN_TITLE,
      valueFunction: (review) => review.epCodes ?
        review.epCodes.join(', ') :
        ''
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_APPELLANT_NAME_COLUMN_TITLE,
      valueFunction: (review) => review.claimantNames ?
        review.claimantNames.join(', ') :
        ''
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_REVIEW_TYPE_COLUMN_TITLE,
      valueFunction: (review) => _.startCase(review.reviewType)
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_EP_STATUS_COLUMN_TITLE,
      valueFunction: (review) => review.epStatus ?
        review.epStatus.join(', ') :
        ''
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_DECISION_DATE_COLUMN_TITLE,
      valueFunction: (review) => review.decisionDate ?
        <DateString date={review.decisionDate} /> :
        ''
    }
  ];

  render = () => <Table
    columns={this.getColumns}
    rowObjects={this.props.reviews}
    getKeyForRow={this.getKeyForRow}
    styling={this.props.styling}
  />
}

CaseListTable.propTypes = {
  reviews: PropTypes.arrayOf(PropTypes.object).isRequired,
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
