import React from 'react';
import PropTypes from 'prop-types';
import IssueModificationRequest from './IssueModificationRequest';
import COPY from '../../../COPY';
import { formatDateStr } from 'app/util/DateUtil';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';

const IssueModificationList = (
  {
    sectionTitle,
    issuesArr,
    lastSection
  }
) => {
  const generateModificationOptions = (optionsLabel) => {
    return [{
      label: `Edit issue ${optionsLabel} request`,
      value: optionsLabel
    },
    {
      label: `Cancel ${optionsLabel} request`,
      value: 'cancel'
    }];
  };

  let details;
  let originalIssue;
  let withDrawal;
  let optionsLabel;

  const issues = issuesArr.map((issue, id) => {
    switch (issue.requestType) {
    case COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE:
      details = COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.DETAILS;
      optionsLabel = 'addition';
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE:
      details = COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.DETAILS;
      optionsLabel = 'modification';
      originalIssue = (
        <>
          <div>
            <h3>Original Issue</h3>
            <div className="issue-modification-request-original">
              <ol>
                <li>
                  <p>{issue.requestIssue.description}</p>
                  <p>Benefit type: {BENEFIT_TYPES[issue.requestIssue.benefitType]}</p>
                  <p>Decision date: {formatDateStr(issue.requestIssue.decisionDate)}</p>
                </li>
              </ol>
            </div>
          </div>
          <br />
        </>
      );
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE:
      details = COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.DETAILS;
      optionsLabel = 'removal';
      break;
    case COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE:
      details = COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DETAILS;
      optionsLabel = 'withdrawal';
      withDrawal = (
        <>
          <br />
          <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DATE}:</h4>
          <p>{formatDateStr(issue.withdrawalDate)}</p>
        </>
      );
      break;
    default:
      break;
    }

    return (
      <li key={id}>
        <IssueModificationRequest
          benefitType={BENEFIT_TYPES[issue.benefitType]}
          decisionDate={formatDateStr(issue.decisionDate)}
          nonRatingIssueCategory={issue.nonRatingIssueCategory}
          nonRatingIssueDescription={issue.nonRatingIssueDescription}
          requestor={issue.requestor}
          requestReason={issue.requestReason}
          details={details}
          originalIssue={originalIssue}
          withDrawal={withDrawal}
          modificationActionOptions={generateModificationOptions(optionsLabel)}
        />
        {issuesArr.length > 1 && id !== issuesArr.length - 1 ?
          <>
            <hr />
            <br />
          </> : null}
      </li>
    );
  });

  return (
    <>
      <div>
        <br />
        <h3>{sectionTitle}</h3>
        <br />
        <ol>
          {issues}
        </ol>
      </div>
      {lastSection ? null : <hr />}
    </>
  );
};

export default IssueModificationList;

IssueModificationList.propTypes = {
  sectionTitle: PropTypes.string.isRequired,
  issuesArr: PropTypes.arrayOf(PropTypes.object).isRequired,
  lastSection: PropTypes.bool.isRequired
};
