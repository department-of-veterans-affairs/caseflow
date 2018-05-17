import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../constants';
import RampElectionPage from './rampElection/completed';
import RampRefilingPage from './rampRefiling/completed';
import SupplementalClaimPage from './supplementalClaim/completed';
import HigherLevelReviewPage from './higherLevelReview/completed';
import AppealPage from './appeal/completed';
import SwitchOnForm from '../components/SwitchOnForm';
import { bindActionCreators } from 'redux';
import { startNewIntake } from '../actions/common';
import Button from '../../components/Button';

class Completed extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionPage />,
        ramp_refiling: <RampRefilingPage />,
        supplemental_claim: <SupplementalClaimPage />,
        higher_level_review: <HigherLevelReviewPage />,
        appeal: <AppealPage />
      }}
      componentForNoFormSelected={<Redirect to={PAGE_PATHS.BEGIN} />}
    />;
}

export default connect(
  ({ intake }) => ({ formType: intake.formType })
)(Completed);

class UnconnectedCompletedNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.startNewIntake();
    this.props.history.push('/');
  }

  render = () => <Button onClick={this.handleClick} legacyStyling={false}>Begin next intake</Button>
}

export const CompletedNextButton = connect(
  null,
  (dispatch) => bindActionCreators({
    startNewIntake
  }, dispatch)
)(UnconnectedCompletedNextButton);
