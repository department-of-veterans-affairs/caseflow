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

  # if task is completed, show this on timeline
  # conditioned to reduce a call to vacols in the absence of a value in `changed_hearing_type` field
  def timeline_title
    if completed?
      "Hearing type converted from #{appeal.previous_hearing_request_type(readable: true)}"\
        " to #{appeal.current_hearing_request_type(readable: true)}"
    end
  end

  def self.hide_from_queue_table_view
    true
  end

  def converted_on
    if completed?
      closed_at
    end
  end

  def converted_by
    if completed?
      appeal.latest_appeal_event.who
    end
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

      # update location to `CASEFLOW`
      AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])

      update!(params)
    end
  end

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end
end
