import React from 'react';
const IssueModification = (
  {
    issue
  }
) => {
  const additionalRequest = (
    <div>
      <p>{issue?.nonrating_issue_category} - {issue?.decision_text}</p>
      <p>Benefit type: {issue?.benefit_type}</p>
      <p>Decision date: {issue?.decision_date}</p>
      <br />
      <h4>Reason for requested issue addition:</h4>
      <p>{issue?.request_reason}</p>
      <br />
      <h4>Requested by:</h4>
      <p>Monte Mann (ACBAUERVVHAH)</p>
    </div>
  );

  const modificationRequest = (
    <div>
      <p>{issue?.nonrating_issue_category} - {issue?.decision_text}</p>
      <p>Benefit type: {issue?.benefit_type}</p>
      <p>Decision date: {issue?.decision_date}</p>
      <br />
      <h4>Reason for requested modification:</h4>
      <p>{issue?.request_reason}</p>
      <br />
      <h4>Requested by:</h4>
      <p>Monte Mann (ACBAUERVVHAH)</p>
      <br />
      <h3>Originial Issue</h3>
      <p>stuff</p>
    </div>
  );

  const removalRequest = (
    <div>
      <p>{issue?.nonrating_issue_category} - {issue?.decision_text}</p>
      <p>Benefit type: {issue?.benefit_type}</p>
      <p>Decision date: {issue?.decision_date}</p>
      <br />
      <h4>Reason for requested removal of issue:</h4>
      <p>{issue?.request_reason}</p>
      <br />
      <h4>Requested by:</h4>
      <p>Monte Mann (ACBAUERVVHAH)</p>
    </div>
  );

  const withdrawalRequest = (
    <div>
      <p>{issue?.nonrating_issue_category} - {issue?.decision_text}</p>
      <p>Benefit type: {issue?.benefit_type}</p>
      <p>Decision date: {issue?.decision_date}</p>
      <br />
      <h4>Reason for requested withdrawal of issue:</h4>
      <p>{issue?.request_reason}</p>
      <br />
      <h4>Requested date for withdrawal:</h4>
      <p>{issue?.withdrawal_request_date}</p>
      <br />
      <h4>Requested by:</h4>
      <p>Monte Mann (ACBAUERVVHAH)</p>
    </div>
  );

  let requestIssue;

  switch (issue.request_type) {
  case 'Addition':
    requestIssue = additionalRequest;
    break;
  case 'Modification':
    requestIssue = modificationRequest;
    break;
  case 'Removal':
    requestIssue = removalRequest;
    break;
  case 'Withdrawal':
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

export default IssueModification;
