import React, { Fragment } from 'react';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../constants';
import { getIntakeStatus } from '../selectors';
import _ from 'lodash';

// appeals
const getAppealChecklistItems = (requestIssues) => [<Fragment>
  <strong>Appeal created:</strong>
  {requestIssues.map((ri, i) => <p key={i}>Issue: {ri.description}</p>)}
</Fragment>];

// higher level reviews & supplemental claims
const getClaimReviewChecklistItems = (formType, requestIssues, isInformalConferenceRequested) => {
  const checklist = [];
  const ratedIssues = requestIssues.filter((ri) => ri.isRated);
  // unidentified issues have undefined isRated
  const nonRatedIssues = requestIssues.filter((ri) => ri.isRated === false);
  const claimReviewName = _.find(FORM_TYPES, { key: formType }).shortName;

  if (ratedIssues.length > 0) {
    checklist.push(<Fragment>
      <strong>A {claimReviewName} Rating EP is being established:</strong>
      {ratedIssues.map((ri, i) => <p key={i}>Contention: {ri.description}</p>)}
    </Fragment>);
  }

  if (nonRatedIssues.length > 0) {
    checklist.push(<Fragment>
      <strong>A {claimReviewName} Nonrating EP is being established:</strong>
      {nonRatedIssues.map((nri, i) => <p key={i}>Contention: {nri.description}</p>)}
    </Fragment>);
  }

  if (isInformalConferenceRequested) {
    checklist.push('Informal Conference Tracked Item');
  }

  return checklist;
};

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

    return <StatusMessage
      title="Intake completed"
      type="success"
      leadMessageList={leadMessageList}
      checklist={formType === 'appeal' ?
        getAppealChecklistItems(requestIssues) :
        getClaimReviewChecklistItems(formType, requestIssues, informalConference)}
      wrapInAppSegment={false}
    />;
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
