import React from 'react';
import StatusMessage from '../../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, RAMP_INTAKE_STATES, REVIEW_OPTIONS } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import _ from 'lodash';

class Completed extends React.PureComponent {
  render() {
    const {
      veteran,
      endProductDescription,
      issues,
      optionSelected,
      rampRefilingStatus
    } = this.props;

    switch (rampRefilingStatus) {
    case RAMP_INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case RAMP_INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case RAMP_INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    if (_.some(issues, 'isSelected')) {
      const messageOpener = `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
          'VA Form 21-4138 has been processed.';

      if (optionSelected === REVIEW_OPTIONS.APPEAL.key) {
        const message = `${messageOpener} You can now begin intake for the next opt-in election.`;

        return <StatusMessage
          title="Appeal record saved in Caseflow"
          type="success"
          leadMessageList={[message]}
          wrapInAppSegment={false}
        />;
      }

      const message = `${messageOpener} Send the “RAMP Acknowledgement Letter”, listing all ` +
          'eligible contentions, and ineligible contentions if applicable.';

      return <StatusMessage
        title="Intake completed"
        type="success"
        leadMessageList={[message]}
        checklist={[
          `Established EP: ${endProductDescription}`,
          'Added contentions to EP'
        ]}
        wrapInAppSegment={false}
      />;

    }

    return <StatusMessage
      title="Ineligible RAMP request"
      type="status"
      leadMessageList={[
        'The Veteran’s RAMP Selection Form did not include any issues that are eligible for ' +
          'review under RAMP. Notify the Veteran using the “RAMP Ineligible Letter”.',
        'You can now begin intake for the next RAMP form.'
      ]}
      wrapInAppSegment={false}
    />;

  }
}

export default connect(
  (state) => ({
    veteran: state.intake.veteran,
    endProductDescription: state.rampRefiling.endProductDescription,
    issues: state.rampRefiling.issues,
    optionSelected: state.rampRefiling.optionSelected,
    rampRefilingStatus: getIntakeStatus(state)
  })
)(Completed);
