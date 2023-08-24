# frozen_string_literal: true
end_product_establishment_ids = [4142, 4143, 4144, 4145]
# :reek:FeatureEnvy
def remove_rs_claims_decision_issues_and_request_decision_issues(end_product_establishment_ids)
  request_issues = RequestIssue.where(end_product_establishment_id: end_product_establishment_ids)
  request_issues.each do |request_issue|
    # Request issues will also need to be reset by removing their processed_at, closed_at, and closed_status values
    decision_issues = request_issue&.decision_issues
    decision_issues.each do |di|
      # delete request decision issues here
      di.request_decision_issues.destroy_all
      # delete decision issue after

      # lookup remand supplemental claims then remove it
      supplemental_claim = SupplementalClaim.find_by(
        veteran_file_number: di.instance_eval { veteran_file_number },
        decision_review_remanded: di.decision_review,
        benefit_type: di.benefit_type
      )
      supplemental_claim.destroy if supplemental_claim
      di.destroy
    end
    request_issue.update(closed_at: nil, closed_status: nil)
  end
end
