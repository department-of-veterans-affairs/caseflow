import React from 'react';
import { getIntakeStatus } from '../../selectors';
import CancelButton from '../../components/CancelButton';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, RAMP_INTAKE_STATES } from '../../constants';
import { connect } from 'react-redux';

class Finish extends React.PureComponent {
  render() {
    const {
      rampRefilingStatus
    } = this.props;

    switch (rampRefilingStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <h1>Finish Processing refiling</h1>;
  }
}

export default connect(
  (state) => ({
    rampRefilingStatus: getIntakeStatus(state)
  })
)(Finish);

export class FinishButtons extends React.PureComponent {
  render = () => <CancelButton />
}
