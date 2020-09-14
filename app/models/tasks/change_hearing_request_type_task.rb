# frozen_string_literal: true

class ChangeHearingRequestTypeTask < Task
  validates :parent, presence: true

  def self.label
    "Change hearing request type"
  end

  def self.hide_from_queue_table_view
    true
  end

  def default_instructions
    [COPY::CHANGE_HEARING_REQUEST_TYPE_TASK_DEFAULT_INSTRUCTIONS]
  end

  def available_actions(user)
    if user.can_change_hearing_request_type?
      [
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIDEO.to_h,
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.to_h
      ]
    else
      []
    end
  end
end
