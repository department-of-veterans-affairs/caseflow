import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import Table from '../components/Table';
import { clearCaseListSearch } from './CaseList/CaseListActions';

import { DateString } from '../util/DateUtil';
import COPY from '../../COPY.json';
import EP_STATUSES from '../../constants/EP_STATUSES.json';

class SubdividedTableRow extends React.PureComponent {
  render = () => {
    const styling = {
      boxSizing: 'content-box',
      height: '22px',
      padding: '10px 15px'
    };
    const topBorderStyle = '1px solid #D6D7D9';

    if (this.props.rowNumber > 0) {
      styling.borderTop = topBorderStyle;
    }

    return <div {...css(styling)}>{this.props.children}</div>;
  }
}

class CaseListTable extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = { styling: {} };
  }

  componentDidMount = () => {
    if (!this.props.reviews) {
      this.setState({ styling: this.props.styling });

      return;
    }

    const styles = {};

    this.props.reviews.forEach((review, i) => {
      if (review.endProducts && review.endProducts.length > 1) {
        styles[`& > tbody > tr:nth-of-type(${i + 1}) > td:nth-of-type(3)`] = { padding: 0 };
        styles[`& > tbody > tr:nth-of-type(${i + 1}) > td:nth-of-type(4)`] = { padding: 0 };
        styles[`& > tbody > tr:nth-of-type(${i + 1}) > td:nth-of-type(5)`] = { padding: 0 };
        styles[`& > tbody > tr:nth-of-type(${i + 1})`] = { verticalAlign: 'top' };
      }
    });

    this.setState({ styling: css(styles) });
  }

  componentWillUnmount = () => this.props.clearCaseListSearch();

  getKeyForRow = (rowNumber, object) => `${object.reviewType}-${object.claimId}`;

  getColumns = () => [
    {
      header: COPY.OTHER_REVIEWS_TABLE_APPELLANT_NAME_COLUMN_TITLE,
      valueFunction: (review) => review.claimantNames.length > 0 ?
        review.claimantNames.join(', ') :
        review.veteranFullName
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_REVIEW_TYPE_COLUMN_TITLE,
      valueFunction: (review) => _.startCase(review.reviewType)
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_EP_CODE_COLUMN_TITLE,
      valueFunction: (review) => {
        const doesReviewHaveEndProducts =
          review.reviewType === 'higher_level_review' &&
          review.endProducts && review.endProducts.length > 0;

        if (doesReviewHaveEndProducts) {
          return review.endProducts.map((endProduct, i) => {
            return <SubdividedTableRow rowNumber={i}>{`${endProduct.code} ${endProduct.modifier}`}</SubdividedTableRow>;
          });
        } else if (review.reviewType === 'supplemental_claim') {
          return <em>{COPY.OTHER_REVIEWS_TABLE_SUPPLEMENTAL_CLAIM_NOTE}</em>;
        }
      }
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_EP_STATUS_COLUMN_TITLE,
      valueFunction: (review) => review.endProducts ?
        review.endProducts.map((endProduct, i) => {
          let statusCode = endProduct.synced_status;

          if (!statusCode) {
            statusCode = 'PROCESSING';
          }

          const epStatus = EP_STATUSES[statusCode];

          return <SubdividedTableRow rowNumber={i}>{epStatus}</SubdividedTableRow>;
        }) : ''
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_DECISION_DATE_COLUMN_TITLE,
      valueFunction: (review) => review.endProducts ?
        review.endProducts.map((endProduct, i) => {
          return <SubdividedTableRow rowNumber={i}>
            {endProduct.last_synced_at && <DateString date={endProduct.last_synced_at} />}
          </SubdividedTableRow>;
        }) : ''
    }
  ];

  render = () => {
    if (!this.props.reviews) {
      return <p>{COPY.OTHER_REVIEWS_TABLE_EMPTY_TEXT}</p>;
    }

    return <Table
      columns={this.getColumns}
      rowObjects={this.props.reviews}
      getKeyForRow={this.getKeyForRow}
      styling={this.state.styling}
    />;
  }
}

CaseListTable.propTypes = {
  reviews: PropTypes.arrayOf(PropTypes.object).isRequired,
  veteranName: PropTypes.string,
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
