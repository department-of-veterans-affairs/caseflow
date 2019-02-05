module BusinessLineTask
  extend ActiveSupport::Concern

  def ui_hash
    serializer_class.new(self).as_json
  end

  def complete_with_payload!(_decision_issue_params, _decision_date)
    return false unless validate_task

    update!(status: Constants.TASK_STATUSES.completed, completed_at: Time.zone.now)
  end

  private

  def business_line
    assigned_to.becomes(BusinessLine)
  end

  def validate_task
    if completed?
      @error_code = :task_completed
    end

    !@error_code
  end
end
