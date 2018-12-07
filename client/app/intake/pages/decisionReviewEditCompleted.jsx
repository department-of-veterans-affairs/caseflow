import React, { Fragment } from 'react';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../constants';
import INELIGIBLE_REQUEST_ISSUES from '../../../constants/INELIGIBLE_REQUEST_ISSUES.json';
import { getIntakeStatus } from '../selectors';
import _ from 'lodash';
import Alert from '../../components/Alert';

const leadMessageList = ({ veteran, formName, requestIssues }) => {
  const unidentifiedIssues = requestIssues.filter((ri) => ri.isUnidentified);

  if (unidentifiedIssues.length === 0) {
    return [
      `${veteran.name}'s (ID #${veteran.fileNumber}) ` +
        `Request for ${formName} has been processed. ` +
        'Go to VBMS claim details and reload to view updates.',
      <strong>Edit the notice letter to reflect the status of requested issues.</strong>
    ];
  }

  const unidentifiedIssuesAlert = <Alert type="warning">
    <h2>Unidentified issue</h2>
    <p>There is still an unidentified issue that needs to be resolved before sending the notice
    letter. Go to VBMS claim details and reload to view updates.</p>
    {unidentifiedIssues.map((ri, i) => <p className="cf-red-text" key={`unidentified-alert-${i}`}>
      Unidentified issue: no issue matched for requested "{ri.description}"
    </p>)}
  </Alert>;

  return [
    `${veteran.name}'s (ID #${veteran.fileNumber}) Request for ${formName} has been processed.`,
    unidentifiedIssuesAlert,
    <strong>Edit the notice letter to reflect the status of requested issues.</strong>
  ];
};

const getEndProductUpdate = ({
  formType,
  isRating,
  issuesBefore,
  issuesAfter,
}) => {
  const claimReviewName = _.find(FORM_TYPES, { key: formType }).shortName;
  const epType = isRating ? 'Rating' : 'Nonrating';
  const issueFilter = isRating
   ? ((i) => !i.ineligibleReason && (i.isRating || i.isUnidentified))
   : ((i) => !i.ineligibleReason && i.isRating === false);
  const filteredIssuesBefore = issuesBefore.filter(issueFilter);
  const filteredIssuesAfter = issuesAfter.filter(issueFilter);
  const epBefore = filteredIssuesBefore.length > 0;
  const epAfter = filteredIssuesAfter.length > 0;
  const epChanged = !_.isEqual(filteredIssuesBefore, filteredIssuesAfter);

  if (epBefore && !epAfter) { // removing ep
    return <Fragment>
      <strong>A {claimReviewName} {epType} EP is being canceled.</strong>
      <p>All contentions on this EP were removed</p>
    </Fragment>;
  } else if (epBefore && epAfter && epChanged) { // updating contentions on ep
    return <Fragment>
      <strong>Contentions on {claimReviewName} {epType} EP are being updated:</strong>
      {filteredIssuesAfter.map((ri, i) => <p key={`${epType}-issue-${i}`}>Contention: {ri.contentionText}</p>)}
    </Fragment>;
  } else if (!epBefore && epAfter) { // establishing ep
    return <Fragment>
      <strong>A {claimReviewName} {epType} EP is being established:</strong>
      {filteredIssuesAfter.map((ri, i) => <p key={`${epType}-issue-${i}`}>Contention: {ri.contentionText}</p>)}
    </Fragment>;
  }
};

const getChecklistItems = (formType, issuesBefore, issuesAfter, isInformalConferenceRequested) => _.compact([
  getEndProductUpdate({
    formType,
    isRating: true,
    issuesBefore,
    issuesAfter
  }),
  getEndProductUpdate({
    formType,
    isRating: false,
    issuesBefore,
    issuesAfter
  }),
  isInformalConferenceRequested ? 'Informal Conference Tracked Item' : null
]);

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

class DecisionReviewEditCompletedPage extends React.PureComponent {
  render() {
    const {
      veteran,
      formType,
      intakeStatus,
      issuesBefore,
      issuesAfter,
      informalConference
    } = this.props;
    if (!issuesBefore) return <Redirect to={PAGE_PATHS.BEGIN} />;

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const ineligibleRequestIssues = issuesAfter.filter((ri) => ri.ineligibleReason);

    return <div><StatusMessage
      title="Claim Issues Saved"
      type="success"
      leadMessageList={leadMessageList({ veteran,
        formName: selectedForm.name,
        requestIssues: issuesAfter })}
      checklist={getChecklistItems(formType, issuesBefore, issuesAfter, informalConference)}
      wrapInAppSegment={false}
    />
    { ineligibleRequestIssues.length > 0 && <IneligibleIssuesList issues={ineligibleRequestIssues} /> }
    </div>
    ;
  }
}

export default connect(
  (state) => ({
    formType: state.formType,
    veteran: state.veteran,
    issuesBefore: state.issuesBefore,
    issuesAfter: state.issuesAfter,
    informalConference: state.informalConference
  })
)(DecisionReviewEditCompletedPage);
