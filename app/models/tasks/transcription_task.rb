# frozen_string_literal: true

class TranscriptionTask < GenericTask
  before_create :check_parent_type

  def check_parent_type
    unless parent.is_a?(AssignHearingDispositionTask) || parent.is_a?(MissingHearingTranscriptsColocatedTask)
      fail(
        Caseflow::Error::InvalidParentTask,
        message: "TranscriptionTask parents must be AssignHearingDispositionTask/MissingHearingTranscriptsColocatedTask"
      )
    end
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if (assigned_to && assigned_to == user) || task_is_assigned_to_users_organization?(user)
      [
        Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h,
        Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.to_h
      ] | hearing_admin_actions
    else
      hearing_admin_actions
    end
  end

  def update_from_params(params, current_user)
    multi_transaction do
      verify_user_can_update!(current_user)

      if params[:status] == Constants.TASK_STATUSES.cancelled
        recreate_hearing
      else
        super(params, current_user)
      end
    end

    [self]
  end

  def hearing_task
    parent.parent
  end

  private

  def recreate_hearing
    # We need to close the parent task and all the sibling tasks as well as open up a new
    # ScheduleHearingTask assigned to the Bva organization
    hearing_task.cancel_task_and_child_subtasks

    ScheduleHearingTask.create!(appeal: appeal, parent: hearing_task.parent)
  end
end
