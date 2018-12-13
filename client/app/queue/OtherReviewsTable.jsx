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

class SubdividedTableRow extends React.PureComponent {
  render = () => {
    let styling;
    const borderStyle = '1px solid #D6D7D9';

    if (this.props.i > 0) {
      styling = css({ borderTop: borderStyle });
    }

    return <div {...styling}>{this.props.content}</div>;
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

    let styles = {};

    this.props.reviews.forEach((review, i) => {
      if (review.epCodes.length > 1) {
        styles[`& > tbody > tr:nth-of-type(${i + 1}) > td:nth-of-type(3)`] = { padding: 0 };
        styles[`& > tbody > tr:nth-of-type(${i + 1}) > td:nth-of-type(4)`] = { padding: 0 };
      }
    });

    debugger;
    const styling = css(styles);

    this.setState({
      styling
    });
  }

  componentWillUnmount = () => this.props.clearCaseListSearch();

  getKeyForRow = (rowNumber, object) => object.id;

  getColumns = () => [
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
      header: COPY.OTHER_REVIEWS_TABLE_EP_CODE_COLUMN_TITLE,
      valueFunction: (review) => review.epCodes ?
        review.epCodes.map((epCode, i) => <SubdividedTableRow content={epCode} i={i}/>) :
        ''
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_EP_STATUS_COLUMN_TITLE,
      valueFunction: (review) => review.epStatus ?
        review.epStatus.map((epStatus, i) => {
          // let styling;
          if (!epStatus) {
            epStatus = 'PROCESSING';
          }

          return <SubdividedTableRow content={epStatus} i={i} />;
        }) : ''
    },
    {
      header: COPY.OTHER_REVIEWS_TABLE_DECISION_DATE_COLUMN_TITLE,
      valueFunction: (review) => review.decisionDate ?
        <DateString date={review.decisionDate} /> :
        ''
    }
  ];

  render = () => {
    debugger;
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
