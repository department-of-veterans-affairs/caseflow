import React from 'react';
import { connect } from 'react-redux';
import CancelButton from '../../components/CancelButton';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, RAMP_INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';

class Finish extends React.PureComponent {
  render() {
    const {
      supplementalClaimStatus
    } = this.props;

    switch (supplementalClaimStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      <h1>Finish page</h1>

    </div>;
  }
}

export class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
    </div>
}

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    supplementalClaimStatus: getIntakeStatus(state)
  })
)(Finish);
