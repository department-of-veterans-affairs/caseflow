import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import Button from '../../../components/Button';
import CancelButton from '../../components/CancelButton';
import NonRatedIssuesUnconnected from '../../components/NonRatedIssues';
import RatedIssuesUnconnected from '../../components/RatedIssues';
import IssueCounter from '../../components/IssueCounter';
import { setIssueSelected, addNonRatedIssue, setIssueCategory, setIssueDescription } from '../../actions/common';
import { completeIntake } from '../../actions/ama';
import { REQUEST_STATE, PAGE_PATHS, INTAKE_STATES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import CompleteIntakeErrorAlert from '../../components/CompleteIntakeErrorAlert';

class Finish extends React.PureComponent {
  render() {
    const {
      supplementalClaimStatus,
      requestState,
      veteranName,
      completeIntakeErrorCode,
      completeIntakeErrorData
    } = this.props;

    switch (supplementalClaimStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      <h1>Identify issues on { veteranName }'s Supplemental Claim (VA Form 21-526b)</h1>

      { requestState === REQUEST_STATE.FAILED &&
        <CompleteIntakeErrorAlert
          completeIntakeErrorCode={completeIntakeErrorCode}
          completeIntakeErrorData={completeIntakeErrorData} />
      }

      <p>
        Please select all the issues that best match the Veteran's request on the form.
        The list below includes issues claimed by the Veteran in the last year.
        If you are unable to find one or more issues, enter these in the "other issues" section.
      </p>

      <RatedIssues />
      <NonRatedIssues />

    </div>;
  }
}

const NonRatedIssues = connect(
  ({ supplementalClaim }) => ({
    nonRatedIssues: supplementalClaim.nonRatedIssues
  }),
  (dispatch) => bindActionCreators({
    addNonRatedIssue,
    setIssueCategory,
    setIssueDescription
  }, dispatch)
)(NonRatedIssuesUnconnected);

const RatedIssues = connect(
  ({ supplementalClaim, intake }) => ({
    intakeId: intake.id,
    reviewState: supplementalClaim
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected
  }, dispatch)
)(RatedIssuesUnconnected);

class FinishNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.completeIntake(this.props.intakeId, this.props.supplementalClaim).then(
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
      disabled={!this.props.supplementalClaim.issueCount}
    >
      Establish EP
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ supplementalClaim, intake }) => ({
    requestState: supplementalClaim.requestStatus.completeIntake,
    intakeId: intake.id,
    supplementalClaim
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

const IssueCounterConnected = connect(
  ({ supplementalClaim }) => ({
    issueCount: supplementalClaim.issueCount
  })
)(IssueCounter);

export class FinishButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <FinishNextButtonConnected history={this.props.history} />
      <IssueCounterConnected />
    </div>
}

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    supplementalClaimStatus: getIntakeStatus(state),
    requestState: state.supplementalClaim.requestStatus.completeIntake,
    completeIntakeErrorCode: state.supplementalClaim.requestStatus.completeIntakeErrorCode,
    completeIntakeErrorData: state.supplementalClaim.requestStatus.completeIntakeErrorData
  })
)(Finish);
