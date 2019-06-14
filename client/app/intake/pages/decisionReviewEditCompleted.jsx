import React, { Fragment } from 'react';
import StatusMessage from '../../components/StatusMessage';
import { connect } from 'react-redux';
import { Redirect } from 'react-router-dom';
import { PAGE_PATHS, FORM_TYPES } from '../constants';
import _ from 'lodash';
import Alert from '../../components/Alert';
import IneligibleIssuesList from '../components/IneligibleIssuesList';
import SmallLoader from '../../components/SmallLoader';
import { LOGO_COLORS } from '../../constants/AppConstants';
import COPY from '../../../COPY.json';

const leadMessageList = ({ veteran, formName, requestIssues, addedIssues }) => {
  const unidentifiedIssues = requestIssues.filter((ri) => ri.isUnidentified);
  const eligibleRequestIssues = requestIssues.filter((ri) => !ri.ineligibleReason);

  const editMessage = () => {
    if (requestIssues.length === 0) {
      return 'removed';
    } else if (_.every(addedIssues, (ri) => ri.withdrawalPending)) {
      return 'withdrawn';
    }

    return 'processed';
  };

  const leadMessageArr = [
    `${veteran.name}'s (ID #${veteran.fileNumber}) Request for ${formName} has been ${editMessage()}.`
  ];

  if (eligibleRequestIssues.length !== 0) {
    if (unidentifiedIssues.length > 0) {
      leadMessageArr.push(
        <Alert type="warning">
          <h2>Unidentified issue</h2>
          <p>{COPY.INDENTIFIED_ALERT}</p>
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
      addedIssues,
      informalConference,
      redirectTo
    } = this.props;

    if (!issuesBefore) {
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    }

    if (redirectTo && formType !== FORM_TYPES.APPEAL.key) {
      window.location.href = redirectTo;

      return <SmallLoader message="Loading ..." spinnerColor={LOGO_COLORS.CERTIFICATION.ACCENT} />;

    }

    const selectedForm = _.find(FORM_TYPES, { key: formType });
    const ineligibleRequestIssues = issuesAfter.filter((ri) => ri.ineligibleReason);
    const withdrawnRequestIssues = addedIssues.filter((ri) => ri.withdrawalPending);
    const hasWithdrawnIssues = !_.isEmpty(withdrawnRequestIssues);
    const editedRequestIssues = addedIssues.filter((ri) => ri.editedDescription);
    const hasEditedRequestIssues = !_.isEmpty(editedRequestIssues);
    const pageTitle = () => {
      if (issuesAfter.length === 0) {
        return 'Review Removed';
      } else if (hasWithdrawnIssues) {
        return 'Review Withdrawn';
      }

      return 'Claim Issues Saved';
    };

    return <div>
      <StatusMessage
        title= {pageTitle()}
        type="success"
        leadMessageList={
          leadMessageList({
            veteran,
            formName: selectedForm.name,
            requestIssues: issuesAfter,
            addedIssues
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
      { hasWithdrawnIssues && <Fragment>
        <ul className="cf-issue-checklist cf-left-padding">
          <li>
            <strong>Withdrawn</strong>
            {withdrawnRequestIssues.map((ri, i) =>
              <p key={`withdrawn-issue-${i}`}>
                {ri.contentionText}
              </p>)}
          </li>
        </ul>
      </Fragment> }
      { hasEditedRequestIssues && <Fragment>
        <ul className="cf-success-checklist cf-left-padding">
          <li>
            <strong>Edited</strong>
            {editedRequestIssues.map((ri, i) =>
              <p key={`withdrawn-issue-${i}`}>
                {ri.editedDescription}
              </p>)}
          </li>
        </ul>
      </Fragment> }
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
    addedIssues: state.addedIssues,
    informalConference: state.informalConference,
    redirectTo: state.redirectTo
  })
)(DecisionReviewEditCompletedPage);
