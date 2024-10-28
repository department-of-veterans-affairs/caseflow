# frozen_string_literal: true

##
# Task for a business line at BVA (e.g., Veteran Readiness & Employment) to review a decision from a judge relating to
# non-compensation benefits like education or loan guarantys.

class DecisionReviewTask < Task
  attr_reader :error_code

  def label
    appeal_type.constantize.review_title
  end

  def serializer_class
    ::WorkQueue::DecisionReviewTaskSerializer
  end

  # The output of this method is used in lieu of ui_hash's whenever gathering task
  # data to populate decision review queues with.
  def serialize_task
    serializer_class.new(self).serializable_hash[:data]
  end

  def ui_hash
    serialize_task[:attributes]
  end

  def complete_with_payload!(decision_issue_params, decision_date, user)
    return false unless validate_task(decision_issue_params, decision_date)

    transaction do
      appeal.create_decision_issues_for_tasks(decision_issue_params, decision_date)
      update!(status: Constants.TASK_STATUSES.completed, closed_at: Time.zone.now, completed_by: user)
      decision_issue_params.each do |param|
        RequestIssue.find(param[:request_issue_id]).close_decided_issue!
      end
    end

    appeal.on_decision_issues_sync_processed if appeal.is_a?(HigherLevelReview)

    true
  end

  delegate :ui_hash, to: :appeal, prefix: true

  private

  def validate_task(decision_issue_params, decision_date)
    if completed?
      @error_code = :task_completed
    elsif !validate_decision_issue_per_request_issue(decision_issue_params)
      @error_code = :invalid_decision_issue_per_request_issue
    elsif !validate_decision_date(decision_date)
      @error_code = :invalid_decision_date
    end

    !@error_code
  end

  def validate_decision_issue_per_request_issue(decision_issue_params)
    appeal.request_issues.active.map(&:id).sort == decision_issue_params.map do |decision_issue_param|
      decision_issue_param[:request_issue_id].to_i
    end.sort
  end

  def validate_decision_date(decision_date)
    return true unless assigned_to.is_a?(VhaBusinessLine)

    dd = decision_date.to_datetime
    dd <= Time.zone.now && dd >= appeal.receipt_date
  end
end
