import React from 'react';
import StatusMessage from '../../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, RAMP_INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';

class Completed extends React.PureComponent {
  render() {
    const {
      veteran,
      endProductDescription,
      rampElectionStatus
    } = this.props;

    switch (rampElectionStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    const message = `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
      'opt-in election has been processed. You can now begin intake for the next opt-in election.';

    return <div>
      <StatusMessage
        title="Intake completed"
        type="success"
        leadMessageList={[message]}
        checklist={[
          'Caseflow closed the VACOLS record',
          `Established EP: ${endProductDescription}`
        ]}
        wrapInAppSegment={false}
      />
    </div>;
  }
}

export default connect(
  (state) => ({
    veteran: state.intake.veteran,
    endProductDescription: state.rampElection.endProductDescription,
    rampElectionStatus: getIntakeStatus(state)
  })
)(Completed);
