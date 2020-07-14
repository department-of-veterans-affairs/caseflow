import React from 'react';
import { connect } from 'react-redux';

import NonCompTabs from '../components/NonCompTabs';
import Button from '../../components/Button';
import { SuccessAlert } from '../components/Alerts';
import { DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { css } from 'glamor';
import PropTypes from 'prop-types';

const pageStyling = css({
  marginRight: 0,
  marginLeft: 0,
  '.usa-grid-full': {
    maxWidth: '1090px'
  }
});

const linkButtonStyling = css({
  marginRight: '7px',
  '.usa-width-two-thirds': {
    width: '59.88078%'
  }
});

const linkStyling = css({ float: 'left',
  paddingBottom: '7px',
  paddingTop: '7px' });

class NonCompReviewsPage extends React.PureComponent {
  businessLineReport = () => {
    if (this.props.businessLine) {
      return <span><a href={`/decision_reviews/${this.props.businessLineUrl}.csv`}
        className="cf-link-btn" {...linkStyling}>Download completed tasks</a>
      </span>;
    }
  }

  render = () => {
    let successAlert = null;

    if (this.props.decisionIssuesStatus?.update === DECISION_ISSUE_UPDATE_STATUS.SUCCEED) {
      successAlert = <SuccessAlert successCode="decisionIssueUpdateSucceeded"
        claimantName={this.props.decisionIssuesStatus.claimantName}
      />;
    }

    return <div>
      { successAlert }
      <h1>{this.props.businessLine}</h1>
      <div className="usa-grid-full" {...pageStyling} >
        <div className="usa-width-two-thirds" {...linkButtonStyling}>
          <h2>Reviews needing action</h2>
          <div>Review each issue and select a disposition</div>
        </div>
        <div className="usa-width-one-thirds cf-txt-r">
          {this.businessLineReport()}
          <Button onClick={() => {
            window.location.href = '/intake';
          }}
          classNames={['usa-button']}
          >
            + Intake new form
          </Button>
        </div>
      </div>
      <NonCompTabs />
    </div>;
  }
}

NonCompReviewsPage.propTypes = {
  businessLine: PropTypes.string,
  decisionIssuesStatus: PropTypes.object,
  businessLineUrl: PropTypes.string
};

const ReviewPage = connect(
  (state) => ({
    businessLine: state.businessLine,
    decisionIssuesStatus: state.decisionIssuesStatus,
    businessLineUrl: state.businessLineUrl
  })
)(NonCompReviewsPage);

export default ReviewPage;
