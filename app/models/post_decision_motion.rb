# frozen_string_literal: true

class PostDecisionMotion < ApplicationRecord
  belongs_to :task, optional: false

  # has_many :decision_issues as: :vacated_issues

  validates :disposition, presence: true
  validate :vacate_type_is_present_if_granted
  validate :vacated_issues_present_if_partial

  enum disposition: {
    granted: "granted",
    partially_granted: "partially_granted",
    denied: "denied",
    withdrawn: "withdrawn",
    dismissed: "dismissed"
  }

  enum vacate_type: {
    straight_vacate: "straight_vacate",
    vacate_and_readjudication: "vacate_and_readjudication",
    vacate_and_de_novo: "vacate_and_de_novo"
  }

  def vacated_issues
    return [] unless vacated_decision_issue_ids

    DecisionIssue.find(vacated_decision_issue_ids)
  end

  def create_request_issues_for_vacature
    vacated_issues.map do |prev_decision_issue|
      RequestIssue.create!(
        decision_review: prev_decision_issue.decision_review,
        decision_review_type: prev_decision_issue.decision_review_type,
        contested_decision_issue_id: prev_decision_issue.id,
        contested_rating_issue_reference_id: prev_decision_issue.rating_issue_reference_id,
        contested_rating_issue_profile_date: prev_decision_issue.rating_profile_date,
        contested_issue_description: prev_decision_issue.description,
        nonrating_issue_category: prev_decision_issue.nonrating_issue_category,
        benefit_type: prev_decision_issue.benefit_type,
        decision_date: prev_decision_issue.caseflow_decision_date,
        veteran_participant_id: task.appeal.veteran.participant_id
      )
    end
  end

  private

  def vacate_type_is_present_if_granted
    return unless granted? || partially_granted?

    errors.add(:vacate_type, "is required for granted disposition") unless vacate_type
  end

  def vacated_issues_present_if_partial
    return unless partially_granted?

    unless vacated_decision_issue_ids
      errors.add(
        :vacated_decision_issue_ids,
        "is required for partially_granted disposition"
      )
    end
  end
end
