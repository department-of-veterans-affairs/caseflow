import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../constants';
import RampElectionPage, { FinishButtons as RampElectionButtons } from './rampElection/finish';
import RampRefilingPage, { FinishButtons as RampRefilingButtons } from './rampRefiling/finish';
import SupplementalClaimPage, { FinishButtons as SupplementalClaimButtons } from './supplementalClaim/finish';
import HigherLevelReviewPage, { FinishButtons as HigherLevelReviewButtons } from './higherLevelReview/finish';
import SwitchOnForm from '../components/SwitchOnForm';

class Finish extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionPage />,
        ramp_refiling: <RampRefilingPage />,
        supplemental_claim: <SupplementalClaimPage />,
        higher_level_review: <HigherLevelReviewPage />
      }}
      componentForNoFormSelected={<Redirect to={PAGE_PATHS.BEGIN} />}
    />;
}

export default connect(
  ({ intake }) => ({ formType: intake.formType })
)(Finish);

class FinishButtonsUnconnected extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionButtons history={this.props.history} />,
        ramp_refiling: <RampRefilingButtons history={this.props.history} />,
        supplemental_claim: <SupplementalClaimButtons history={this.props.history} />,
        higher_level_review: <HigherLevelReviewButtons history={this.props.history} />
      }}
    />
}

export const FinishButtons = connect(
  ({ intake }) => ({ formType: intake.formType })
)(FinishButtonsUnconnected);
