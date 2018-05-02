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
      higherLevelReviewStatus
    } = this.props;

    switch (higherLevelReviewStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    const message = `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
      'Request for Higher Level Review (VA Form 20-0988) has been processed.';

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
    endProductDescription: state.higherLevelReview.endProductDescription,
    higherLevelReviewStatus: getIntakeStatus(state)
  })
)(Completed);
