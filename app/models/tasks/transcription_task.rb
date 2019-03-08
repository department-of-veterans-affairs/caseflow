# frozen_string_literal: true

class TranscriptionTask < GenericTask
  before_create :check_parent_type

  class NonDispositionTaskParent < StandardError; end

  def check_parent_type
    fail NonDispositionTaskParent unless parent.is_a? DispositionTask
  end

  def available_actions(user)
    if (assigned_to && assigned_to == user) || task_is_assigned_to_users_organization?(user)
      return [Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h, Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h]
    end

    []
  end

  def complete_transcription_data(_user)
    {
      modal_body: COPY::COMPLETE_TRANSCRIPTION_BODY
    }
  end

  def assign_to_hearing_schedule_team_data(_user)
    {
      redirect_after: "/queue/appeals/#{appeal.external_id}",
      modal_title: COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_TITLE,
      modal_body: COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_BODY,
      message_title: format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_TITLE, appeal.veteran_full_name),
      message_detail: format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_BODY, appeal.veteran_full_name),
      type: ScheduleHearingTask.name
    }
  end

  def hearing_task
    parent.parent
  end
end
