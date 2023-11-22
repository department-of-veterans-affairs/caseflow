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

const NonCompReviewsPage = ({
  businessLine,
  decisionIssuesStatus,
  businessLineUrl,
  isBusinessLineAdmin,
  canGenerateClaimHistory,
  history }) => {

  const downloadCsv = () => {
    location.href = `/decision_reviews/${businessLineUrl}.csv`;
  };

  const successAlert = decisionIssuesStatus?.update === DECISION_ISSUE_UPDATE_STATUS.SUCCEED ?
    <SuccessAlert
      successCode="decisionIssueUpdateSucceeded"
      claimantName={decisionIssuesStatus.claimantName}
    /> :
    null;

  return (
    <NonCompLayout>
      { successAlert }
      <h1>{businessLine}</h1>
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
            styling={compReviewButtonStyling}
          >
            + Intake new form
          </Button>
          {businessLine &&
            <Button
              classNames={secondaryButtonClassNames}
              onClick={downloadCsv}
              styling={compReviewButtonStyling}>
              Download completed tasks
            </Button>
          }
          {canGenerateClaimHistory && isBusinessLineAdmin ?
            <Button
              classNames={secondaryButtonClassNames}
              onClick={() => {
                history.push(`${businessLineUrl}/report`);
              }}
              styling={compReviewButtonStyling}
            >
              Generate task report
            </Button> :
            null
          }
        </div>
      </div>
      <NonCompTabs />
    </NonCompLayout>
  );
};

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
