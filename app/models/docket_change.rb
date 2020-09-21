# frozen_string_literal: true

class DocketChange < CaseflowRecord
  include HasSimpleAppealUpdatedSince

  belongs_to :appeal
  belongs_to :task, optional: false

  validates :disposition, presence: true
  validate :granted_issues_present_if_partial

  delegate :request_issues, to: :appeal

  enum disposition: {
    granted: "granted",
    partially_granted: "partially_granted",
    denied: "denied"
  }

  def decision_issues_for_switch
    return [] unless granted_decision_issue_ids

    DecisionIssue.find(granted_decision_issue_ids)
  end

  # Creates request issues on the new docket contesting the decisions to be granted
  def create_request_issues_for_switch
    decision_issues_for_switch.map { |di| di.create_contesting_request_issue!(appeal) }
  end

  def granted_decision_issues
    @granted_decision_issues ||= request_issues.map { |ri| ri.decision_issues.first }
  end

  def create_granted_decision_issues
    request_issues.map(&:create_granted_decision_issue!)
  end

  private

  def granted_issues_present_if_partial
    return unless partially_granted?

    unless granted_decision_issue_ids
      errors.add(
        :granted_decision_issue_ids,
        "is required for partially_granted disposition"
      )
    end
  end
end
