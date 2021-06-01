# frozen_string_literal: true

##
# Task created when a hearing coordinator visits the Case Details page of an appeal with a
# Travel Board hearing request. Gives the user the option to convert that request to a video
# or virtual hearing request so it can be scheduled in Caseflow.
#
# When task is completed, i.e the field `changed_hearing_request_type` is passed as payload, the location
# of LegacyAppeal is moved `CASEFLOW` and the parent `ScheduleHearingTask` is set to be `assigned`
class ChangeHearingRequestTypeTask < Task
  include RunAsyncable

  validates :parent, presence: true

  before_validation :set_assignee

  def self.label
    "Change hearing request type"
  end

  # if task is completed, show this on timeline
  # conditioned to reduce a call to vacols in the absence of a value in `changed_hearing_type` field
  def timeline_title
    if completed?
      "Hearing type converted from #{appeal.readable_previous_hearing_request_type_for_task(id)}"\
        " to #{appeal.readable_current_hearing_request_type_for_task(id)}"
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
    appeal.last_converted_by if completed?
  end

  def default_instructions
    [COPY::CHANGE_HEARING_REQUEST_TYPE_TASK_DEFAULT_INSTRUCTIONS]
  end

  def available_actions(user)
    if user.can_change_hearing_request_type?
      [
        Constants.TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.to_h,
        Constants.TASK_ACTIONS.CANCEL_CONVERT_HEARING_REQUEST_TYPE_TO_VIRTUAL.to_h
      ]
    else
      []
    end
  end

  def update_from_params(params, user)
    payload_values = params.delete(:business_payloads)&.dig(:values)

    if payload_values&.[](:changed_hearing_request_type).present?
      update_appeal_and_self(payload_values, params)

      [self]
    elsif params[:status] == Constants.TASK_STATUSES.cancelled
      cancel_self_and_hearing_task_parents_without_callbacks
    else
      super(params, user)
    end
  end

  private

  # If a ChangeHearingRequestTypeTask is being canceled, we want to revert the task tree to an
  # approximation of the state it was in before it and its parent hearing tasks were created.
  # This method cancels the task and all of its hearing task ancestors and siblings without
  # triggering callbacks that might automatically create other tasks or change the appeal's
  # location in VACOLS.
  def cancel_self_and_hearing_task_parents_without_callbacks
    ancestor_task_of_type(HearingTask)&.cancel_task_and_child_subtasks
  end

  def update_appeal_and_self(payload_values, params)
    multi_transaction do
      # save the original request type if needed
      appeal.remember_original_hearing_request_type
      appeal.update!(
        changed_hearing_request_type: payload_values[:changed_hearing_request_type],
        closest_regional_office: payload_values[:closest_regional_office]
      )

      # in VACOLS, update location to `CASEFLOW` and save the new hearing request type
      if appeal.is_a?(LegacyAppeal)
        AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
        AppealRepository.update_vacols_hearing_request_type!(appeal, payload_values[:changed_hearing_request_type])
      end

      update!(params)
    end

    perform_later_or_now(Hearings::GeomatchAndCacheAppealJob, appeal_id: appeal.id, appeal_type: appeal.class.name)
  end

  def set_assignee
    self.assigned_to ||= Bva.singleton
  end
end
