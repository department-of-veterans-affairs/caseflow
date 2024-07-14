import { isEmpty } from 'lodash';
import { v4 } from 'uuid';
import { formatDateStrUtc } from '../../util/DateUtil';

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
      withdrawalDate: formatDateStrUtc(modificationRequest.withdrawal_date, 'YYYY-MM-DD'),
      // Serialized Object fields
      requestIssue: formatRequestIssueForPendingRequest(modificationRequest.request_issue),
      requestor: formatUserForPendingRequest(modificationRequest.requestor),
      decider: formatUserForPendingRequest(modificationRequest.decider),
      identifier: String(modificationRequest.id) || v4()
    };
  });
};

export const formatIssueModificationRequestSubmissionData = (state) => {
  const groupedRequests = {
    new: [],
    cancelled: [],
    edited: [],
    decided: []
  };

  (state.pendingIssueModificationRequests || []).
    forEach((modificationRequest) => {
      const formattedRequest = {
        id: modificationRequest.id,
        status: modificationRequest.status,
        request_type: modificationRequest.requestType,
        benefit_type: modificationRequest.benefitType,
        nonrating_issue_category: modificationRequest.nonratingIssueCategory,
        nonrating_issue_description: modificationRequest.nonratingIssueDescription,
        decision_date: modificationRequest.decisionDate,
        withdrawal_date: modificationRequest.withdrawalDate,
        request_reason: modificationRequest.requestReason,
        decision_reason: modificationRequest.decisionReason,
        request_issue_id: modificationRequest.requestIssueId,
        remove_original_issue: modificationRequest.removeOriginalIssue,
      };

      if (isEmpty(modificationRequest.id)) {
        groupedRequests.new.push(formattedRequest);
      } else if (modificationRequest.edited) {
        groupedRequests.edited.push(formattedRequest);
      } else if (modificationRequest.status === 'cancelled') {
        groupedRequests.cancelled.push(formattedRequest);
      } else if (modificationRequest.status === 'approved' || modificationRequest.status === 'denied') {
        groupedRequests.decided.push(formattedRequest);
      }
    });

  return groupedRequests;
};

export const convertPendingIssueToRequestIssue = (issueModificationRequest) => {
  const { nonratingIssueCategory, nonratingIssueDescription } = issueModificationRequest;

  const requestIssueId = issueModificationRequest.requestIssue?.id ?
    String(issueModificationRequest.requestIssue?.id) :
    null;

  return {
    id: requestIssueId,
    benefitType: issueModificationRequest.benefitType,
    description: nonratingIssueDescription,
    nonRatingIssueDescription: nonratingIssueDescription,
    decisionDate: issueModificationRequest.decisionDate,
    category: nonratingIssueCategory,
    editable: true,
    // This is a one to many, but there should only ever be one assigned/pending issue modification request per issue
    issueModificationRequestId: issueModificationRequest.id
  };
};
