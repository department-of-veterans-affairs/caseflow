import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../constants';
import RampElectionPage, { ReviewButtons as RampElectionButtons } from './rampElection/review';
import RampRefilingPage, { ReviewButtons as RampRefilingButtons } from './rampRefiling/review';
import SupplementalClaimPage, { ReviewButtons as SupplementalClaimButtons } from './supplementalClaim/review';
import HigherLevelReviewPage, { ReviewButtons as HigherLevelReviewButtons } from './higherLevelReview/review';
import AppealReviewPage, { ReviewButtons as AppealReviewButtons } from './appeal/review';

import SwitchOnForm from '../components/SwitchOnForm';

class Review extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionPage />,
        ramp_refiling: <RampRefilingPage />,
        supplemental_claim: <SupplementalClaimPage />,
        higher_level_review: <HigherLevelReviewPage />,
        appeal: <AppealReviewPage />
      }}
      componentForNoFormSelected={<Redirect to={PAGE_PATHS.BEGIN} />}
    />;
}

export default connect(
  ({ intake }) => ({ formType: intake.formType })
)(Review);

class ReviewButtonsUnconnected extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionButtons history={this.props.history} />,
        ramp_refiling: <RampRefilingButtons history={this.props.history} />,
        supplemental_claim: <SupplementalClaimButtons history={this.props.history} />,
        higher_level_review: <HigherLevelReviewButtons history={this.props.history} />,
        appeal: <AppealReviewButtons history={this.props.history} />
      }}
    />
}

export const ReviewButtons = connect(
  ({ intake }) => ({ formType: intake.formType })
)(ReviewButtonsUnconnected);
