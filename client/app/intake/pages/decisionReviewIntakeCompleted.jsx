import React, { Fragment } from 'react';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../constants';
import INELIGIBLE_REQUEST_ISSUES from '../../../constants/INELIGIBLE_REQUEST_ISSUES.json';
import { getIntakeStatus } from '../selectors';
import _ from 'lodash';

const getChecklistItems = (formType, requestIssues, isInformalConferenceRequested) => {
  const checklist = [];
  const eligibleRequestIssues = requestIssues.filter((ri) => !ri.ineligibleReason);
  let eligibleRatingRequestIssues = [];
  let eligibleNonratingRequestIssues = [];

  if (formType !== 'appeal') {
    eligibleRatingRequestIssues = eligibleRequestIssues.filter((ri) => ri.isRating || ri.isUnidentified);
    eligibleNonratingRequestIssues = eligibleRequestIssues.filter((ri) => ri.isRating === false);
  }

  const claimReviewName = _.find(FORM_TYPES, { key: formType }).shortName;

  if (formType === 'appeal') {
    checklist.push(<Fragment>
      <strong>Appeal created:</strong>
      {eligibleRequestIssues.map((ri, i) => <p key={i}>Issue: {ri.contentionText}</p>)}
    </Fragment>);
  }

  if (eligibleRatingRequestIssues.length > 0) {
    checklist.push(<Fragment>
      <strong>A {claimReviewName} Rating EP is being established:</strong>
      {eligibleRatingRequestIssues.map((ri, i) => <p key={`rating-issue-${i}`}>Contention: {ri.contentionText}</p>)}
    </Fragment>);
  }

  if (eligibleNonratingRequestIssues.length > 0) {
    checklist.push(<Fragment>
      <strong>A {claimReviewName} Nonrating EP is being established:</strong>
      {eligibleNonratingRequestIssues.map((nri, i) => <p key={`nonrating-issue-${i}`}>
        Contention: {nri.contentionText}
      </p>)}
    </Fragment>);
  }

  if (isInformalConferenceRequested) {
    checklist.push('Informal Conference Tracked Item');
  }

  return checklist;
};

const ineligibilityCopy = (issue) => {
  if (issue.titleOfActiveReview) {
    return INELIGIBLE_REQUEST_ISSUES.duplicate_of_issue_in_active_review.replace(
      '{review_title}', issue.titleOfActiveReview
    );
  } else if (issue.ineligibleReason) {
    return INELIGIBLE_REQUEST_ISSUES[issue.ineligibleReason];
  }
};

class IneligibleIssuesList extends React.PureComponent {
  render = () =>
    <Fragment>
      <ul className="cf-ineligible-checklist cf-left-padding">
        <li>
          <strong>Ineligible</strong>
          {this.props.issues.map((ri, i) =>
            <p key={`ineligible-issue-${i}`} className="cf-red-text">
              {ri.contentionText} {ineligibilityCopy(ri)}
            </p>)}
        </li>
      </ul>
    </Fragment>;
}

class DecisionReviewIntakeCompleted extends React.PureComponent {
  render() {
    const {
      veteran,
      formType,
      intakeStatus
    } = this.props;
    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const completedReview = this.props.decisionReviews[selectedForm.key];
    const {
      requestIssues,
      informalConference
    } = completedReview;
    const ineligibleRequestIssues = requestIssues.filter((ri) => ri.ineligibleReason);

    switch (intakeStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.REVIEWED:
      return <Redirect to={PAGE_PATHS.FINISH} />;
    default:
    }

    const leadMessageList = [
      `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
        `Request for ${selectedForm.name} has been processed. ` +
        'If you need to edit this, go to VBMS claim details and click the “Edit in Caseflow” button.',
      <strong>Edit the notice letter to reflect the status of requested issues.</strong>
    ];

    return <div><StatusMessage
      title="Intake completed"
      type="success"
      leadMessageList={leadMessageList}
      checklist={getChecklistItems(formType, requestIssues, informalConference)}
      wrapInAppSegment={false}
    />
    { ineligibleRequestIssues.length > 0 && <IneligibleIssuesList issues={ineligibleRequestIssues} /> }
    </div>
    ;
  }
}

export default connect(
  (state) => ({
    veteran: state.intake.veteran,
    formType: state.intake.formType,
    decisionReviews: {
      higher_level_review: state.higherLevelReview,
      supplemental_claim: state.supplementalClaim,
      appeal: state.appeal
    },
    intakeStatus: getIntakeStatus(state)
  })
)(DecisionReviewIntakeCompleted);
