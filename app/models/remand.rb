# frozen_string_literal: true

class Remand < SupplementalClaim

  def create_issues
    create_issues!(build_request_issues)
  end

  def build_request_issues
    remanded_decision_issues_needing_request_issues.map do |remand_decision_issue|
      RequestIssue.new(
        decision_review: self,
        contested_decision_issue_id: remand_decision_issue.id,
        contested_rating_issue_reference_id: remand_decision_issue.rating_issue_reference_id,
        contested_rating_issue_profile_date: remand_decision_issue.rating_profile_date,
        contested_issue_description: remand_decision_issue.description,
        nonrating_issue_category: remand_decision_issue.nonrating_issue_category,
        benefit_type: benefit_type,
        decision_date: remand_decision_issue.approx_decision_date
      )
    end
  end

  def remanded_decision_issues_needing_request_issues
    decision_issues.remanded.uncontested.where(benefit_type: benefit_type)
  end
end
