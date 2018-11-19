import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import Button from '../../../components/Button';
import CancelButton from '../../components/CancelButton';
import NonratingRequestIssuesUnconnected from '../../components/NonratingRequestIssues';
import RatingRequestIssuesUnconnected from '../../components/RatingRequestIssues';
import IssueCounter from '../../components/IssueCounter';
import {
  completeIntake,
  setIssueSelected,
  newNonratingRequestIssue,
  setIssueCategory,
  setIssueDescription,
  setIssueDecisionDate
} from '../../actions/decisionReview';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES, REQUEST_STATE } from '../../constants';
import { getIntakeStatus, issueCountSelector } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';

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
      <h1>Identify issues on { veteranName }'s { FORM_TYPES.HIGHER_LEVEL_REVIEW.name }</h1>

      { requestState === REQUEST_STATE.FAILED &&
        <ErrorAlert
          errorCode={completeIntakeErrorCode}
          errorData={completeIntakeErrorData} />
      }

      <p>
        Please select all the issues that best match the Veteran's request on the form.
        The list below includes issues claimed by the Veteran in the last year.
        If you are unable to find one or more issues, enter these in the "other issues" section.
      </p>

      <RatingRequestIssues />
      <NonratingRequestIssues />
    </div>;
  }
}

const NonratingRequestIssues = connect(
  ({ higherLevelReview }) => ({
    nonRatingRequestIssues: higherLevelReview.nonRatingRequestIssues
  }),
  (dispatch) => bindActionCreators({
    newNonratingRequestIssue,
    setIssueCategory,
    setIssueDescription,
    setIssueDecisionDate
  }, dispatch)
)(NonratingRequestIssuesUnconnected);

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
      disabled={!this.props.issueCount && !this.props.addedIssues}
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

const RatingRequestIssues = connect(
  ({ higherLevelReview }) => ({
    ratings: higherLevelReview.ratings
  }),
  (dispatch) => bindActionCreators({
    setIssueSelected
  }, dispatch)
)(RatingRequestIssuesUnconnected);

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
