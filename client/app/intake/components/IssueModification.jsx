import React from 'react';
const IssueModification = (
  {
    issue
  }
) => {
  return (
    <div>
      <p>{issue?.nonrating_issue_category} - {issue?.decision_text}</p>
      <p>Benefit type: {issue?.benefit_type}</p>
      <p>Decision date: {issue?.decision_date}</p>
      <br />
      <h4>Reason for requested issues addition:</h4>
      <p>{issue?.request_reason}</p>
      <br />
      <h4>Requested by:</h4>
      <p>Monte Mann (ACBAUERVVHAH)</p>
    </div>
  );
};

export default IssueModification;
