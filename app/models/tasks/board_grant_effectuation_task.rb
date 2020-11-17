# frozen_string_literal: true

##
# A task to track when the Board grants a benefit that is not compensation or pension,
# like education or a loan guaranty, otherwise known as an "effectuation task".
# This task is created for the appropriate business lines based on the benefit types of the decision issues.

class BoardGrantEffectuationTask < DecisionReviewTask
  include BusinessLineTask

  def label
    "Board Grant"
  end

  def serializer_class
    ::WorkQueue::BoardGrantEffectuationTaskSerializer
  end

  def appeal_ui_hash
    appeal.ui_hash.merge(
      requestIssues: request_issues_by_benefit_type.map(&:serialize)
    )
  end

  private

  def request_issues_by_benefit_type
    appeal.request_issues.active_or_ineligible.select do |issue|
      issue.benefit_type == business_line.url
    end
  end
end
