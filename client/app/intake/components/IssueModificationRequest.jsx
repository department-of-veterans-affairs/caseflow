import React from 'react';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';

const IssueModificationRequest = (
  {
    issue
  }
) => {
  const modificationIssueInfo = (
    <div>
      <p>{issue.nonRatingIssueCategory} - {issue.nonRatingIssueDescription}</p>
      <p>Benefit type: {issue.benefitType}</p>
      <p>Decision date: {issue.decisionDate}</p>
      <br />
    </div>
  );

  const requestedByUser = (
    <div>
      <br />
      <h4>Requested by:</h4>
      <p>{issue.requestor}</p>
      <br />
    </div>
  );

  const originalIssue = (
    <div>
      <h3>Original Issue</h3>
      <p>issue?.requestIssue.nonratingIssueCategory - issue?.requestIssue.nonratingIssueDescription</p>
      <p>Benefit type: issue?.requestIssue.benefitType</p>
      <p>Decision date: issue?.requestIssue.decisionDate</p>
    </div>
  );

  const additionalRequest = (
    <div>
      {modificationIssueInfo}
      <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.DETAILS}:</h4>
      <p>{issue.requestReason}</p>
      {requestedByUser}
    </div>
  );

  const modificationRequest = (
    <div>
      {modificationIssueInfo}
      <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.DETAILS}:</h4>
      <p>{issue.requestReason}</p>
      {requestedByUser}
      {originalIssue}
      <br />
    </div>
  );

  const removalRequest = (
    <div>
      {modificationIssueInfo}
      <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.DETAILS}:</h4>
      <p>{issue.requestReason}</p>
      {requestedByUser}
    </div>
  );

  const withdrawalRequest = (
    <div>
      {modificationIssueInfo}
      <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DETAILS}:</h4>
      <p>{issue.requestReason}</p>
      <br />
      <h4>{COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.DATE}:</h4>
      <p>{issue.withdrawalDate}</p>
      {requestedByUser}
    </div>
  );

  let requestIssue;

  switch (issue.requestType) {
  case COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.REQUEST_TYPE:
    requestIssue = additionalRequest;
    break;
  case COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.REQUEST_TYPE:
    requestIssue = modificationRequest;
    break;
  case COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.REQUEST_TYPE:
    requestIssue = removalRequest;
    break;
  case COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.REQUEST_TYPE:
    requestIssue = withdrawalRequest;
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
