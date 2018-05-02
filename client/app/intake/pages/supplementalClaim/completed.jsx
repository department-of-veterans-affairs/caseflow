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
      supplementalClaimStatus
    } = this.props;

    switch (supplementalClaimStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    const message = `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
      'Request for Supplemental Claim (VA Form 21-526b) has been processed.';

    return <div>
      <StatusMessage
        title="Intake completed"
        type="success"
        leadMessageList={[message]}
        checklist={[
          'Reviewed Form',
          'Selected issues',
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
    endProductDescription: state.supplementalClaim.endProductDescription,
    supplementalClaimStatus: getIntakeStatus(state)
  })
)(Completed);
