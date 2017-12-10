import React from 'react';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { FORM_TYPES, PAGE_PATHS } from '../constants';
import RampElectionPage, { ReviewButtons as RampElectionButtons } from './rampElection/review';
import RampRefilingPage, { ReviewButtons as RampRefilingButtons } from './rampRefiling/review';

class Review extends React.PureComponent {
  render() {
    const { formType } = this.props;

    switch (formType) {
    case FORM_TYPES.RAMP_ELECTION.key:
      return <RampElectionPage />;
    case FORM_TYPES.RAMP_REFILING.key:
      return <RampRefilingPage />;
    default:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }
  }
}

export default connect(
  ({ formType }) => ({ formType })
)(Review);

class ReviewButtonsUnconnected extends React.PureComponent {
  render() {
    const { formType } = this.props;

    switch (formType) {
    case FORM_TYPES.RAMP_ELECTION.key:
      return <RampElectionButtons history={this.props.history} />;
    case FORM_TYPES.RAMP_REFILING.key:
      return <RampRefilingButtons history={this.props.history} />;
    default:
      return <div></div>;
    }
  }
}

export const ReviewButtons = connect(
  ({ formType }) => ({ formType })
)(ReviewButtonsUnconnected);

