import React from 'react';
import { connect } from 'react-redux';

import NonCompTabs from '../components/NonCompTabs';
import Button from '../../components/Button';
import { SuccessAlert } from '../components/Alerts';
import { DECISION_ISSUE_UPDATE_STATUS } from '../constants';

class NonCompReviewsPage extends React.PureComponent {
  render = () => {
    let successAlert = null;

    if (this.props.decisionIssuesStatus.update === DECISION_ISSUE_UPDATE_STATUS.SUCCEED) {
      successAlert = <SuccessAlert successCode="decisionIssueUpdateSucceeded"
        claimantName={this.props.decisionIssuesStatus.claimantName}
      />;
    }

    return <div>
      { successAlert }
      <h1>{this.props.businessLine}</h1>
      <div className="usa-grid-full">
        <div className="usa-width-two-thirds">
          <h2>Reviews needing action</h2>
          <div>Review each issue and select a disposition</div>
        </div>
        <div className="usa-width-one-thirds cf-txt-r">
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

const ReviewPage = connect(
  (state) => ({
    businessLine: state.businessLine,
    decisionIssuesStatus: state.decisionIssuesStatus
  })
)(NonCompReviewsPage);

export default ReviewPage;
