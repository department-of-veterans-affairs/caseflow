import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../constants';
import RampElectionPage, { FinishButtons as RampElectionButtons } from './rampElection/finish';
import RampRefilingPage, { FinishButtons as RampRefilingButtons } from './rampRefiling/finish';
import SwitchOnForm from '../components/SwitchOnForm';

class Finish extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionPage />,
        ramp_refiling: <RampRefilingPage />
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
        ramp_refiling: <RampRefilingButtons history={this.props.history} />
      }}
    />
}

export const FinishButtons = connect(
  ({ intake }) => ({ formType: intake.formType })
)(FinishButtonsUnconnected);

