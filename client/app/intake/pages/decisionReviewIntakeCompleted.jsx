import React, { Fragment } from 'react';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../constants';
import INTAKE_STRINGS from '../../../constants/INTAKE_STRINGS.json';
import { getIntakeStatus } from '../selectors';
import _ from 'lodash';
import Alert from '../../components/Alert';
import { legacyIssue } from '../util/issues';
import IneligibleIssuesList from '../components/IneligibleIssuesList';
import SmallLoader from '../../components/SmallLoader';
import { LOGO_COLORS } from '../../constants/AppConstants';

const leadMessageList = ({ veteran, formName, requestIssues }) => {
  const unidentifiedIssues = requestIssues.filter((ri) => ri.isUnidentified);
  const eligibleRequestIssues = requestIssues.filter((ri) => !ri.ineligibleReason);

  const leadMessageArr = [`${veteran.name}'s (ID #${veteran.fileNumber}) Request for ${formName} has been processed.`];

  if (eligibleRequestIssues.length !== 0) {
    if (unidentifiedIssues.length > 0) {
      leadMessageArr.push(
        <Alert type="warning">
          <h2>Unidentified issue</h2>
          <p>There is still an unidentified issue that needs to be resolved before sending the notice
          letter. To edit, go to VBMS claim details and click the “Edit in Caseflow” button.</p>
          {unidentifiedIssues.map((ri, i) => <p className="cf-red-text" key={`unidentified-alert-${i}`}>
            Unidentified issue: no issue matched for requested "{ri.description}"
          </p>)}
        </Alert>
      );
    } else {
      leadMessageArr.push(
        'If you need to edit this, go to VBMS claim details and click the “Edit in Caseflow” button.'
      );
    }
  }

  leadMessageArr.push(
    <strong>Edit the notice letter to reflect the status of requested issues.</strong>
  );

  return leadMessageArr;
};

const getChecklistItems = (formType, requestIssues, isInformalConferenceRequested) => {
  const eligibleRequestIssues = requestIssues.filter((ri) => !ri.ineligibleReason);

  if (formType === 'appeal') {
    return [<Fragment>
      <strong>Appeal created:</strong>
      {eligibleRequestIssues.map((ri, i) => <p key={`appeal-issue-${i}`}>Issue: {ri.contentionText}</p>)}
    </Fragment>];
  }

  const checklist = [];
  const eligibleRatingRequestIssues = eligibleRequestIssues.filter((ri) => ri.isRating || ri.isUnidentified);
  const eligibleNonratingRequestIssues = eligibleRequestIssues.filter((ri) => ri.isRating === false);
  const claimReviewName = _.find(FORM_TYPES, { key: formType }).shortName;

  if (eligibleRatingRequestIssues.length > 0) {
    checklist.push(<Fragment>
      <strong>A {claimReviewName} Rating EP is being established:</strong>
      {
        eligibleRatingRequestIssues.map(
          (ri, i) => <p key={`rating-issue-${i}`}>Contention: {ri.contentionText}</p>
        )
      }
    </Fragment>);
  }

  if (eligibleNonratingRequestIssues.length > 0) {
    checklist.push(<Fragment>
      <strong>A {claimReviewName} Nonrating EP is being established:</strong>
      {
        eligibleNonratingRequestIssues.map(
          (nri, i) => <p key={`nonrating-issue-${i}`}>Contention: {nri.contentionText}</p>
        )
      }
    </Fragment>);
  }

  if (eligibleRequestIssues.length > 0 && isInformalConferenceRequested) {
    checklist.push('Informal Conference Tracked Item');
  }

  return checklist;
};

class VacolsOptInList extends React.PureComponent {
  render = () =>
    <Fragment>
      <ul className="cf-success-checklist cf-left-padding">
        <li>
          <strong>{INTAKE_STRINGS.vacols_optin_issue_closed}</strong>
          {this.props.issues.map((ri, i) =>
            <p key={`vacols-issue-${i}`} className="">
              {legacyIssue(ri, this.props.legacyAppeals).description}
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
      informalConference,
      legacyAppeals
    } = completedReview;

    switch (intakeStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.STARTED:
      return <Redirect to={PAGE_PATHS.REVIEW} />;
    case INTAKE_STATES.REVIEWED:
      if (formType === FORM_TYPES.RAMP_ELECTION.key || formType === FORM_TYPES.RAMP_REFILING.key) {
        return <Redirect to={PAGE_PATHS.FINISH} />;
      }

      return <Redirect to={PAGE_PATHS.ADD_ISSUES} />;
    default:
    }

    const ineligibleRequestIssues = requestIssues.filter((ri) => ri.ineligibleReason);
    const vacolsOptInIssues = requestIssues.filter((ri) => ri.vacolsId && !ri.ineligibleReason);

    if (completedReview.processedInCaseflow && formType !== FORM_TYPES.APPEAL.key) {
      // we do not use Redirect because state no longer matters,
      // and because we are likely not in a relative URL path any more.
      window.location = completedReview.redirectTo;

      return <SmallLoader message="Creating task..." spinnerColor={LOGO_COLORS.CERTIFICATION.ACCENT} />;
    }

    return <div><StatusMessage
      title="Intake completed"
      type="success"
      leadMessageList={
        leadMessageList({
          veteran,
          formName: selectedForm.name,
          requestIssues
        })
      }
      checklist={
        getChecklistItems(
          formType,
          requestIssues,
          informalConference
        )
      }
      wrapInAppSegment={false}
    />
    { vacolsOptInIssues.length > 0 && <VacolsOptInList issues={vacolsOptInIssues} legacyAppeals={legacyAppeals} /> }
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
