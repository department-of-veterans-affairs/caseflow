import React from 'react';
import { connect } from 'react-redux';

import NonCompTabs from '../components/NonCompTabs';
import Button from '../../components/Button';
import { SuccessAlert } from '../components/Alerts';
import { DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import NonCompLayout from '../components/NonCompLayout';

const pageStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginRight: 0,
  marginLeft: 0,
});

const linkButtonStyling = css({
  marginRight: '7px',
});

const buttonContainerStyling = css({
  display: 'flex',
  gap: '12px'
});

const compReviewButtonStyling = css({
  whiteSpace: 'nowrap',
});

const secondaryButtonClassNames = ['usa-button-secondary'];

class NonCompReviewsPage extends React.PureComponent {
  downloadCsv = () => {
    location.href = `/decision_reviews/${this.props.businessLineUrl}.csv`;
  }

  render = () => {
    let successAlert = null;

    if (this.props.decisionIssuesStatus?.update === DECISION_ISSUE_UPDATE_STATUS.SUCCEED) {
      successAlert = <SuccessAlert successCode="decisionIssueUpdateSucceeded"
        claimantName={this.props.decisionIssuesStatus.claimantName}
      />;
    }

    return (
      <NonCompLayout>
        { successAlert }
        <h1>{this.props.businessLine}</h1>
        <div {...pageStyling} >
          <div className="usa-width-one-half" {...linkButtonStyling}>
            <h2>Reviews needing action</h2>
            <div>Review each issue and select a disposition</div>
          </div>
          <div className="cf-txt-r" {...buttonContainerStyling}>
            <Button
              onClick={() => {
                window.location.href = '/intake';
              }}
              classNames={compReviewButtonStyling}
              styling={compReviewButtonStyling}
            >
              + Intake new form
            </Button>
            {this.props.businessLine &&
              <Button
                classNames={secondaryButtonClassNames}
                onClick={this.downloadCsv}
                styling={compReviewButtonStyling}>
                Download completed tasks
              </Button>
            }
            {this.props.canGenerateClaimHistory && this.props.isBusinessLineAdmin ?
              <Button
                classNames={secondaryButtonClassNames}
                onClick={() => {
                  this.props.history.push(`${this.props.businessLineUrl}/report`);
                }}
                styling={compReviewButtonStyling}
              >
                Generate task report
              </Button> :
              null
            }
            {this.props.canGenerateClaimHistory && this.props.isBusinessLineAdmin && (
              <Button
                classNames={secondaryButtonClassNames}
                onClick={() => {
                  this.props.history.push(`${this.props.businessLineUrl}/show-all-history`);
                }}
                styling={compReviewButtonStyling}
              >
                Show All History
              </Button>
            )
            }
          </div>
        </div>
        <NonCompTabs />
      </NonCompLayout>
    );
  }
}

NonCompReviewsPage.propTypes = {
  businessLine: PropTypes.string,
  decisionIssuesStatus: PropTypes.object,
  businessLineUrl: PropTypes.string,
  isBusinessLineAdmin: PropTypes.bool,
  canGenerateClaimHistory: PropTypes.bool,
  history: PropTypes.object,
};

const ReviewPage = connect(
  (state) => ({
    isBusinessLineAdmin: state.nonComp.isBusinessLineAdmin,
    businessLine: state.nonComp.businessLine,
    canGenerateClaimHistory: state.nonComp.businessLineConfig.canGenerateClaimHistory,
    decisionIssuesStatus: state.nonComp.decisionIssuesStatus,
    businessLineUrl: state.nonComp.businessLineUrl
  })
)(NonCompReviewsPage);

export default ReviewPage;
