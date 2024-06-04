const formatRequestIssueForPendingRequest = (requestIssue) => {
  if (!requestIssue) {
    return;
  }

  return {
    id: String(requestIssue.id),
    benefitType: requestIssue.benefit_type,
    decisionDate: requestIssue.decision_date,
    nonratingIssueCategory: requestIssue.nonrating_issue_category,
    nonratingIssueDescription: requestIssue.nonrating_issue_description
  };
};

const formatUserForPendingRequest = (user) => {
  if (!user) {
    return;
  }

  return {
    id: String(user.id),
    fullName: user.full_name,
    cssId: user.css_id,
    stationID: String(user.station_id)
  };
};

// formatIssueModificationRequests takes an array of issueModificationRequests in the server ui_hash format
// and returns objects useful for displaying in UI
export const formatIssueModificationRequests = (issueModificationRequests) => {
  if (!issueModificationRequests) {
    return;
  }

  return issueModificationRequests.map((modificationRequest) => {
    return {
      // All the standard issue modification request fields
      id: String(modificationRequest.id),
      benefitType: modificationRequest.benefit_type,
      status: modificationRequest.status,
      requestType: modificationRequest.request_type,
      removeOriginalIssue: modificationRequest.remove_original_issue,
      nonratingIssueDescription: modificationRequest.nonrating_issue_description,
      nonratingIssueCategory: modificationRequest.nonrating_issue_category,
      decisionDate: modificationRequest.decision_date,
      decisionReason: modificationRequest.decision_reason,
      requestReason: modificationRequest.request_reason,
      requestIssueId: modificationRequest.request_issue_id,
      withdrawalDate: modificationRequest.withdrawal_date,
      // Serialized Object fields
      requestIssue: formatRequestIssueForPendingRequest(modificationRequest.request_issue),
      requestor: formatUserForPendingRequest(modificationRequest.requestor),
      decider: formatUserForPendingRequest(modificationRequest.decider),
    };
  });
};
