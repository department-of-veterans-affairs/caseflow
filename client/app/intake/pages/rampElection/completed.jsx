import React from 'react';
import StatusMessage from '../../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';

class Completed extends React.PureComponent {
  render() {
    const {
      veteran,
      endProductDescription,
      rampElectionStatus
    } = this.props;

    switch (rampElectionStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    const message = `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
      'opt-in election has been processed.';

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
