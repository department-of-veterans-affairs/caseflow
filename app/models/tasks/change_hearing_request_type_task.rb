# frozen_string_literal: true

##
# Task created when a hearing coordinator visits the Case Details page of an appeal with a
# Travel Board hearing request. Gives the user the option to convert that request to a video
# or virtual hearing request so it can be scheduled in Caseflow.
class ChangeHearingRequestTypeTask < Task
  validates :parent, presence: true

  before_validation :set_assignee

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
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.to_h
      ]
    else
      []
    end
  end

  def update_from_params(params, user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    if payload_values[:changed_request_type].present?
      update_appeal_and_self(payload_values, params)

      [self]
    else
      super(params, user)
    end
  end

  private

  def update_appeal_and_self(payload_values, params)
    multi_transaction do
      appeal.update!(changed_request_type: payload_values[:changed_request_type])

      update!(params)
    end
  end

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end
end
