import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS } from '../constants';
import RampElectionPage, { ReviewButtons as RampElectionButtons } from './rampElection/review';
import RampRefilingPage, { ReviewButtons as RampRefilingButtons } from './rampRefiling/review';
import SwitchOnForm from '../components/SwitchOnForm';

class Review extends React.PureComponent {
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
  ({ formType }) => ({ formType })
)(Review);

class ReviewButtonsUnconnected extends React.PureComponent {
  render = () =>
    <SwitchOnForm
      formComponentMapping={{
        ramp_election: <RampElectionButtons history={this.props.history} />,
        ramp_refiling: <RampRefilingButtons history={this.props.history} />
      }}
    />
}

export const ReviewButtons = connect(
  ({ formType }) => ({ formType })
)(ReviewButtonsUnconnected);

