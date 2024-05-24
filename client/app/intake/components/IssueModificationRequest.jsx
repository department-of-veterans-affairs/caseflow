import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';
import { formatDateStr } from 'app/util/DateUtil';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';

const IssueModificationRequest = ({ issue }) => {
  const formatDecisionDate = (decisionDate) => {
    return formatDateStr(decisionDate);
  };

  const modificationIssueInfo = (
    <div>
      <p>{issue.nonRatingIssueCategory} - {issue.nonRatingIssueDescription}</p>
      <p>Benefit type: {BENEFIT_TYPES[issue.benefitType]}</p>
      <p>Decision date: {formatDecisionDate(issue.decisionDate)}</p>
      <br />
    </div>
  );

  const requestedByUser = (
    <div>
      <br />
      <h4>Requested by:</h4>
      <p>{issue.requestor.fullName} ({issue.requestor.cssId})</p>
      <br />
    </div>
  );

  let requestIssue;

  switch (issue.requestType) {
  case COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE:
    requestIssue = (
      <>
        {modificationIssueInfo}
        <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.DETAILS}:</h4>
        <p>{issue.requestReason}</p>
        {requestedByUser}
      </>
    );
    break;
  case COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE:
    requestIssue = (
      <>
        {modificationIssueInfo}
        <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.DETAILS}:</h4>
        <p>{issue.requestReason}</p>
        {requestedByUser}
        <div>
          <h3>Original Issue</h3>
          <div className="issue-modification-request-original">
            <ol>
              <li>
                <p>{issue.requestIssue.description}</p>
                <p>Benefit type: {BENEFIT_TYPES[issue.requestIssue.benefitType]}</p>
                <p>Decision date: {formatDecisionDate(issue.requestIssue.decisionDate)}</p>
              </li>
            </ol>
          </div>
        </div>
        <br />
      </>
    );
    break;
  case COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE:
    requestIssue = (
      <>
        {modificationIssueInfo}
        <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.DETAILS}:</h4>
        <p>{issue.requestReason}</p>
        {requestedByUser}
      </>
    );
    break;
  case COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE:
    requestIssue = (
      <>
        {modificationIssueInfo}
        <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DETAILS}:</h4>
        <p>{issue.requestReason}</p>
        <br />
        <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DATE}:</h4>
        <p>{formatDecisionDate(issue.withdrawalDate)}</p>
        {requestedByUser}
      </>
    );
    break;
  default:
    break;
  }

  return (
    <div>
      {requestIssue}
    </div>
  );
};

export default IssueModificationRequest;

IssueModificationRequest.propTypes = {
  issue: PropTypes.object
};
