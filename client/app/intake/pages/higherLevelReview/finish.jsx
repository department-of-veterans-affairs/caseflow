import React from 'react';
import { connect } from 'react-redux';
import CancelButton from '../../components/CancelButton';
import { Redirect } from 'react-router-dom';
import { completeIntake } from '../../actions/higherLevelReview';
import { bindActionCreators } from 'redux';
import { PAGE_PATHS, RAMP_INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import CompleteIntakeErrorAlert from '../../components/CompleteIntakeErrorAlert';

class Finish extends React.PureComponent {
  render() {
    const {
      higherLevelReviewStatus,
      requestState,
      veteranName,
      completeIntakeErrorCode,
      completeIntakeErrorData
    } = this.props;

    switch (higherLevelReviewStatus) {
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

      { requestState === REQUEST_STATE.FAILED &&
        <CompleteIntakeErrorAlert
          completeIntakeErrorCode={completeIntakeErrorCode}
          completeIntakeErrorData={completeIntakeErrorData} />
      }

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
    higherLevelReviewStatus: getIntakeStatus(state),
    requestState: state.higherLevelReview.requestStatus.completeIntake,
    completeIntakeErrorCode: state.higherLevelReview.requestStatus.completeIntakeErrorCode,
    completeIntakeErrorData: state.higherLevelReview.requestStatus.completeIntakeErrorData
  })
)(Finish);
