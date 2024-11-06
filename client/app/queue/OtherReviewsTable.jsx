import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import Table from '../components/Table';
import { clearCaseListSearch } from './CaseList/CaseListActions';
import BadgeArea from '../components/badges/BadgeArea';

import COPY from '../../COPY';
import CLAIM_REVIEW_TEXT from '../../constants/CLAIM_REVIEW_TEXT';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { DateString } from '../util/DateUtil';

class SubdividedTableRow extends React.PureComponent {
  render = () => {
    const styling = {
      boxSizing: 'content-box',
      minHeight: '2.2rem',
      padding: '1rem 1.2rem'
    };

    const topBorderStyle = '1px solid #D6D7D9';

    if (this.props.rowNumber > 0) {
      styling.borderTop = topBorderStyle;
    }

    return <div {...css(styling)}>{this.props.children}</div>;
  }
}

class OtherReviewsTable extends React.PureComponent {
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
      if (review.endProductStatuses && review.endProductStatuses.length > 1) {
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

  getColumns = () => {
    const { featureToggles } = this.props;

    // Check if disable_ama_eventing is false to determine whether to show the BadgeArea column
    const showBadgeAreaColumn = !featureToggles.disable_ama_eventing;

    const columns = [
      {
        header: COPY.OTHER_REVIEWS_TABLE_APPELLANT_NAME_COLUMN_TITLE,
        valueFunction: (review) => review.claimantNames.length > 0 ?
          review.claimantNames.join(', ') :
          review.veteranFullName
      },
      {
        header: COPY.OTHER_REVIEWS_TABLE_REVIEW_TYPE_COLUMN_TITLE,
        valueFunction: (review) => (
          <React.Fragment>
            <Link
              name="edit-issues"
              href={review.editIssuesUrl}
              target="_blank">
              {_.startCase(review.reviewType)}
            </Link>
          </React.Fragment>
        )
      },
      {
        header: COPY.OTHER_REVIEWS_TABLE_RECEIPT_DATE_COLUMN_TITLE,
        valueFunction: (review) => <DateString date={review.receiptDate} />
      },
      {
        header: COPY.OTHER_REVIEWS_TABLE_EP_CODE_COLUMN_TITLE,
        valueFunction: (review) => {
          if (review.endProductStatuses && review.endProductStatuses.length > 0) {
            if (review.endProductStatuses.length > 1) {
              return review.endProductStatuses.map((endProduct, i) => (
                <SubdividedTableRow key={i} rowNumber={i}>
                  {endProduct.ep_code}
                </SubdividedTableRow>
              ));
            }
            const endProduct = review.endProductStatuses[0];

            return endProduct.ep_code;
          }

          return <em>{COPY[CLAIM_REVIEW_TEXT[review.reviewType]]}</em>;
        }
      },
      {
        header: COPY.OTHER_REVIEWS_TABLE_EP_STATUS_COLUMN_TITLE,
        valueFunction: (review) => {
          if (review.endProductStatuses && review.endProductStatuses.length > 0) {
            if (review.endProductStatuses.length > 1) {
              return review.endProductStatuses.map((endProduct, i) => (
                <SubdividedTableRow key={i} rowNumber={i}>
                  {endProduct.ep_status}
                </SubdividedTableRow>
              ));
            }
            const endProduct = review.endProductStatuses[0];

            return endProduct.ep_status;
          }

          return '';
        }
      }
    ];

    // Conditionally include the BadgeArea column at the start of row based on showBadgeAreaColumn
    if (showBadgeAreaColumn) {
      columns.unshift({
        valueFunction: (review) => <BadgeArea review={review} />
      });
    }

    return columns;
  };

  render = () => {
    if (this.props.reviews.length === 0) {
      return <p>{COPY.OTHER_REVIEWS_TABLE_EMPTY_TEXT}</p>;
    }

    return <Table
      className="cf-other-reviews-table"
      columns={this.getColumns}
      rowObjects={this.props.reviews}
      getKeyForRow={this.getKeyForRow}
      styling={this.state.styling}
    />;
  }
}

SubdividedTableRow.propTypes = {
  rowNumber: PropTypes.number,
  children: PropTypes.node
};

OtherReviewsTable.propTypes = {
  reviews: PropTypes.arrayOf(PropTypes.object).isRequired,
  veteranName: PropTypes.string,
  styling: PropTypes.object,
  clearCaseListSearch: PropTypes.func,
  featureToggles: PropTypes.object
};

const mapStateToProps = (state) => ({
  userCssId: state.ui.userCssId,
  userRole: state.ui.userRole,
  featureToggles: state.ui.featureToggles
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(OtherReviewsTable);
