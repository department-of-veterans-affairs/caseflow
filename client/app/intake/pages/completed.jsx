import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../constants';
import RampElectionPage from './rampElection/completed';
import RampRefilingPage from './rampRefiling/completed';
import DecisionReviewIntakeCompletedPage from './decisionReviewIntakeCompleted';
import SwitchOnForm from '../components/SwitchOnForm';
import { bindActionCreators } from 'redux';
import { startNewIntake } from '../actions/intake';
import Button from '../../components/Button';

class Completed extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionPage />,
        ramp_refiling: <RampRefilingPage />,
        supplemental_claim: <DecisionReviewIntakeCompletedPage />,
        higher_level_review: <DecisionReviewIntakeCompletedPage />,
        appeal: <DecisionReviewIntakeCompletedPage />
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

  render = () => <Button onClick={this.handleClick}>Begin next intake</Button>
}

export const CompletedNextButton = connect(
  null,
  (dispatch) => bindActionCreators({
    startNewIntake
  }, dispatch)
)(UnconnectedCompletedNextButton);
