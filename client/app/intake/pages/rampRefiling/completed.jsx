import React from 'react';
import StatusMessage from '../../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, REVIEW_OPTIONS } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import _ from 'lodash';
import COPY from '../../../../COPY.json';

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
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    if (_.some(issues, 'isSelected')) {
      const messageOpener = `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
          'VA Form 21-4138 has been processed.';

      if (optionSelected === REVIEW_OPTIONS.APPEAL.key) {
        const message = `${messageOpener} ${COPY.APPEAL_RECORD_SAVED_MESSAGE}`;

        return <StatusMessage
          title="Appeal record saved in Caseflow"
          type="success"
          leadMessageList={[message]}
          wrapInAppSegment={false}
        />;
      }

      const message = `${messageOpener} ${COPY.RAMP_COMPLETED_ALERT}`;

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
        COPY.INELIGIBLE_RAMP_ALERT,

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
