import React from 'react';
import { connect } from 'react-redux';
import Button from '../../../components/Button';
import TabWindow from '../../../components/TabWindow';
import CancelButton from '../../components/CancelButton';
import NonRatedIssues from './nonRatedIssues';
import RatedIssues from './ratedIssues';
import { Redirect } from 'react-router-dom';

import { completeIntake } from '../../actions/higherLevelReview';
import { bindActionCreators } from 'redux';
import { REQUEST_STATE, PAGE_PATHS, RAMP_INTAKE_STATES } from '../../constants';
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

    const tabs = [{
      label: 'Rated issues',
      page: <RatedIssues />
    }, {
      label: 'Non-rated issues',
      page: <NonRatedIssues />
    }];

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
      <h1>Finish processing { veteranName }'s Higher-Level Review (VA Form 20-0988)</h1>

      <p>
        Select or enter the issue(s) that best match the form you are processing.
        If the Veteran listed any non-rated issues, use the "Non-rated issues" tab,
        and Caseflow will establish a non-rated EP for any non-rated issue(s).
      </p>

      <TabWindow
        name="higher-level-review-tabwindow"
        tabs={tabs} />

      { requestState === REQUEST_STATE.FAILED &&
        <CompleteIntakeErrorAlert
          completeIntakeErrorCode={completeIntakeErrorCode}
          completeIntakeErrorData={completeIntakeErrorData} />
      }

    </div>;
  }
}

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.higherLevelReview).then(
      (completeWasSuccessful) => {
        if (completeWasSuccessful) {
          this.props.history.push('/completed');
        }
      }
    );
  }

  render = () =>
    <Button
      name="finish-intake"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      legacyStyling={false}
    >
      Establish claim
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ higherLevelReview, intake }) => ({
    requestState: higherLevelReview.requestStatus.completeIntake,
    intakeId: intake.id,
    higherLevelReview
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

export class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <FinishNextButtonConnected history={this.props.history} />
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
