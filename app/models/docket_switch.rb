# frozen_string_literal: true

class DocketSwitch < CaseflowRecord
  belongs_to :old_docket_stream, class_name: "Appeal", optional: false
  belongs_to :new_docket_stream, class_name: "Appeal"
  belongs_to :task, optional: false

  validates :disposition, presence: true
  validate :granted_issues_present_if_partial

  delegate :request_issues, to: :old_docket_stream

  enum disposition: {
    granted: "granted",
    partially_granted: "partially_granted",
    denied: "denied"
  }

  def request_issues_for_switch
    return [] unless granted_request_issue_ids

    RequestIssue.find(granted_request_issue_ids)
  end

  def move_granted_request_issues
    request_issues_for_switch.map { |ri| ri.update!(decision_review: new_docket_stream) }
  end

  private

  def granted_issues_present_if_partial
    return unless partially_granted?

    unless granted_request_issue_ids
      errors.add(
        :granted_request_issue_ids,
        "is required for partially_granted disposition"
      )
    end
  end
end
