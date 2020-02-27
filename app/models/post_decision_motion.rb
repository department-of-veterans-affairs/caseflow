# frozen_string_literal: true

class PostDecisionMotion < ApplicationRecord
  belongs_to :appeal
  belongs_to :task, optional: false

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

  def decision_issues_for_vacatur
    return [] unless vacated_decision_issue_ids

    DecisionIssue.find(vacated_decision_issue_ids)
  end

  def request_issues_for_vacatur
    @request_issues_for_vacatur ||= RequestIssue.where(contested_decision_issue_id: vacated_decision_issue_ids)
  end

  def create_request_issues_for_vacatur
    decision_issues_for_vacatur.map { |di| di.create_contesting_request_issue!(appeal) }
  end

  def vacated_decision_issues
    @vacated_decision_issues ||= request_issues_for_vacatur.map { |ri| ri.decision_issues.first }
  end

  def create_vacated_decision_issues
    request_issues_for_vacatur.map(&:create_vacated_decision_issue!)
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
