import React, { Fragment } from 'react';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, FORM_TYPES } from '../constants';
import _ from 'lodash';
import Alert from '../../components/Alert';
import IneligibleIssuesList from '../components/IneligibleIssuesList';

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

const getEndProductUpdate = ({
  formType,
  isRating,
  issuesBefore,
  issuesAfter
}) => {
  const claimReviewName = _.find(FORM_TYPES, { key: formType }).shortName;
  const epType = isRating ? 'Rating' : 'Nonrating';
  const issueFilter = isRating ?
    (i) => !i.ineligibleReason && (i.isRating || i.isUnidentified) :
    (i) => !i.ineligibleReason && i.isRating === false;
  const epIssuesBefore = issuesBefore.filter(issueFilter);
  const epIssuesAfter = issuesAfter.filter(issueFilter);
  const epBefore = epIssuesBefore.length > 0;
  const epAfter = epIssuesAfter.length > 0;
  const epChanged = !_.isEqual(epIssuesBefore, epIssuesAfter);

  if (epBefore && !epAfter) {
    return <Fragment>
      <strong>A {claimReviewName} {epType} EP is being canceled.</strong>
      <p>All contentions on this EP were removed</p>
    </Fragment>;
  } else if (epBefore && epAfter && epChanged) {
    return <Fragment>
      <strong>Contentions on {claimReviewName} {epType} EP are being updated:</strong>
      {
        epIssuesAfter.map(
          (ri, i) => <p key={`${epType}-issue-${i}`}>Contention: {ri.contentionText}</p>
        )
      }
    </Fragment>;
  } else if (!epBefore && epAfter) {
    return <Fragment>
      <strong>A {claimReviewName} {epType} EP is being established:</strong>
      {
        epIssuesAfter.map(
          (ri, i) => <p key={`${epType}-issue-${i}`}>Contention: {ri.contentionText}</p>
        )
      }
    </Fragment>;
  }
};

const getChecklistItems = (formType, issuesBefore, issuesAfter, isInformalConferenceRequested) => {
  const eligibleRequestIssues = issuesAfter.filter((i) => !i.ineligibleReason);

  return _.compact([
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
    (eligibleRequestIssues.length > 0 && isInformalConferenceRequested) ? 'Informal Conference Tracked Item' : null
  ]);
};

class DecisionReviewEditCompletedPage extends React.PureComponent {
  render() {
    const {
      veteran,
      formType,
      issuesBefore,
      issuesAfter,
      informalConference
    } = this.props;

    if (!issuesBefore) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const ineligibleRequestIssues = issuesAfter.filter((ri) => ri.ineligibleReason);

    return <div>
      <StatusMessage
        title="Claim Issues Saved"
        type="success"
        leadMessageList={
          leadMessageList({
            veteran,
            formName: selectedForm.name,
            requestIssues: issuesAfter
          })
        }
        checklist={
          getChecklistItems(
            formType,
            issuesBefore,
            issuesAfter,
            informalConference
          )
        }
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
