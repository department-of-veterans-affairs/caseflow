import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import Button from '../../../components/Button';
import CancelButton from '../../components/CancelButton';
import NonRatedIssuesUnconnected from '../../components/NonRatedIssues';
import RatedIssuesUnconnected from '../../components/RatedIssues';
import IssueCounter from '../../components/IssueCounter';
import {
  completeIntake,
  setIssueSelected,
  addNonRatedIssue,
  setIssueCategory,
  setIssueDescription,
  setIssueDecisionDate
} from '../../actions/ama';
import { REQUEST_STATE, PAGE_PATHS, INTAKE_STATES } from '../../constants';
import { getIntakeStatus, issueCountSelector } from '../../selectors';
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
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      <h1>Identify issues on { veteranName }'s Higher-Level Review (VA Form 20-0988)</h1>

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
  ({ higherLevelReview }) => ({
    nonRatedIssues: higherLevelReview.nonRatedIssues
  }),
  (dispatch) => bindActionCreators({
    addNonRatedIssue,
    setIssueCategory,
    setIssueDescription,
    setIssueDecisionDate
  }, dispatch)
)(NonRatedIssuesUnconnected);

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
      disabled={!this.props.issueCount}
    >
      Establish EP
    </Button>;
}

const FinishNextButtonConnected = connect(
  ({ higherLevelReview, intake }) => ({
    requestState: higherLevelReview.requestStatus.completeIntake,
    intakeId: intake.id,
    higherLevelReview,
    issueCount: issueCountSelector(higherLevelReview)
  }),
  (dispatch) => bindActionCreators({
    completeIntake
  }, dispatch)
)(FinishNextButton);

const mapStateToProps = (state) => {
  return {
    issueCount: issueCountSelector(state.higherLevelReview)
  };
};

const IssueCounterConnected = connect(mapStateToProps)(IssueCounter);

const RatedIssues = connect(
  ({ higherLevelReview, intake }) => ({
    intakeId: intake.id,
    reviewState: higherLevelReview
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected
  }, dispatch)
)(RatedIssuesUnconnected);

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
    higherLevelReviewStatus: getIntakeStatus(state),
    requestState: state.higherLevelReview.requestStatus.completeIntake,
    completeIntakeErrorCode: state.higherLevelReview.requestStatus.completeIntakeErrorCode,
    completeIntakeErrorData: state.higherLevelReview.requestStatus.completeIntakeErrorData
  })
)(Finish);
