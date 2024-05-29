import { formatRequestIssues } from './issues';

// formatIssueModificationRequests takes an array of issueModificationRequests in the server ui_hash format
// and returns objects useful for displaying in UI
export const formatIssueModificationRequests = (issueModificationRequests) => {
  if (!issueModificationRequests) {
    return;
  }

  return issueModificationRequests.map((modificationRequest) => {
    return {
      // All the standard issue modification fields
      id: String(modificationRequest.id),
      benefitType: modificationRequest.benefit_type,
      status: modificationRequest.status,
      requestType: modificationRequest.request_type,
      removeOriginalIssue: modificationRequest.remove_original_issue,
      nonRatingIssueDescription: modificationRequest.nonrating_issue_description,
      nonRatingIssueCategory: modificationRequest.nonrating_issue_category,
      decisionDate: modificationRequest.decision_date,
      decisionReason: modificationRequest.decision_reason,
      requestReason: modificationRequest.request_reason,
      requestIssueId: modificationRequest.request_issue_id,
      // Serialized Object fields
      requestIssue: formatRequestIssues(modificationRequest.request_issue),
      requestor: modificationRequest.requestor,
      decider: modificationRequest.decider,
      // Extra fields that may or may not be needed later
      decisionIssueId: modificationRequest.contested_decision_issue_id,
      description: modificationRequest.description,
      ineligibleReason: modificationRequest.ineligible_reason,
      ineligibleDueToId: modificationRequest.ineligible_due_to_id,
      decisionReviewTitle: modificationRequest.decision_review_title,
      contentionText: modificationRequest.contention_text,
      untimelyExemption: modificationRequest.untimelyExemption,
      untimelyExemptionNotes: modificationRequest.untimelyExemptionNotes,
      vacolsId: modificationRequest.vacols_id,
      vacolsSequenceId: modificationRequest.vacols_sequence_id,
      vacolsIssue: modificationRequest.vacols_issue,
      endProductCleared: modificationRequest.end_product_cleared,
      endProductCode: modificationRequest.end_product_establishment_code || modificationRequest.end_product_code,
      withdrawalDate: modificationRequest.withdrawal_date,
      editable: modificationRequest.editable,
      examRequested: modificationRequest.exam_requested,
      isUnidentified: modificationRequest.is_unidentified,
      notes: modificationRequest.notes,
      category: modificationRequest.category,
      isRating: !modificationRequest.category,
      ratingIssueReferenceId: modificationRequest.rating_issue_reference_id,
      ratingDecisionReferenceId: modificationRequest.rating_decision_reference_id,
      approxDecisionDate: modificationRequest.approx_decision_date,
      titleOfActiveReview: modificationRequest.title_of_active_review,
      rampClaimId: modificationRequest.ramp_claim_id,
      verifiedUnidentifiedIssue: modificationRequest.verified_unidentified_issue,
      isPreDocketNeeded: modificationRequest.is_predocket_needed,
      mstChecked: modificationRequest.mst_status,
      pactChecked: modificationRequest.pact_status,
      mst_status_update_reason_notes: modificationRequest?.mstJustification,
      pact_status_update_reason_notes: modificationRequest?.pactJustification
    };
  });
};
