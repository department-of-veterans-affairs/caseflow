import React from 'react';
import { connect } from 'react-redux';
import { FinishButtons as RampElectionButtons } from './rampElection/finish';
import { FinishButtons as RampRefilingButtons } from './rampRefiling/finish';
import { FinishButtons as SupplementalClaimButtons } from './supplementalClaim/finish';
import { FinishButtons as HigherLevelReviewButtons } from './higherLevelReview/finish';
import { FinishButtons as AppealButtons } from './appeal/finish';
import SwitchOnForm from '../components/SwitchOnForm';

class FinishButtonsUnconnected extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionButtons history={this.props.history} />,
        ramp_refiling: <RampRefilingButtons history={this.props.history} />,
        supplemental_claim: <SupplementalClaimButtons history={this.props.history} />,
        higher_level_review: <HigherLevelReviewButtons history={this.props.history} />,
        appeal: <AppealButtons history={this.props.history} />
      }}
    />
}

export const FinishButtons = connect(
  ({ intake }) => ({ formType: intake.formType })
)(FinishButtonsUnconnected);
