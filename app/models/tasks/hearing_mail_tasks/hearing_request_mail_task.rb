# frozen_string_literal: true

##
# Task to serve as interface with shared methods for the following hearings mail tasks:
#   - HearingPostponementRequestMailTask
#   - HearingWithdrawalRequestMailTask
# HearingRequestMailTask is itself not an assignable task type
##
class HearingRequestMailTask < MailTask
  include RunAsyncable
  validates :parent, presence: true, on: :create

  before_validation :verify_request_type_designated

  class HearingAssociationMissing < StandardError
    def initialize
      super(format(COPY::HEARING_TASK_ASSOCIATION_MISSING_MESSAGE, hearing_task_id))
    end
  end

  class << self
    def allow_creation?(*)
      false
    end

    # All descendant postponement/withdrawal tasks will initially be assigned to the Hearing Admin org
    def default_assignee(_task)
      HearingAdmin.singleton
    end
  end

  def available_actions(_user)
    []
  end

  # Purpose: Only show task assigned to "HearingAdmin" on the Case Timeline
  # Params: None
  # Return: boolean if task is assigned to MailTeam
  def hide_from_case_timeline
    assigned_to.is_a?(MailTeam)
  end

  # Purpose: Determines if there is a hearing with an open AssignHearingDispositionTask to postpone or withdraw
  # Params: None
  # Return: The open hearing if one exists
  def open_hearing
    @open_hearing ||= open_assign_hearing_disposition_task&.hearing
  end

  # Purpose: Gives the latest hearing task
  # Params: None
  # Return: The hearing task
  def hearing_task
    @hearing_task ||= open_assign_hearing_disposition_task&.hearing_task || active_schedule_hearing_task&.parent
  end

  # Purpose: Postponement - When a hearing is postponed through the completion of a NoShowHearingTask,
  #          AssignHearingDispositionTask, or ChangeHearingDispositionTask, cancel any open
  #          HearingPostponementRequestMailTasks in that appeal's task tree
  #
  #          Withdrawal - When a withdraw hearing action is completed through a ScheduleHearingTask,
  #          AssignHearingDispositionTask, or ChangeHearingDispositionTask, cancel any open
  #          HearingWithdrawalRequestMailTasks in that appeal's task tree
  #
  # Params: completed_task - task object of the completed task through which hearing was postponed/withdrawn
  #         updated_at - datetime when the task was completed
  #
  # Return: The cancelled HPR mail tasks
  def cancel_when_redundant(completed_task, updated_at)
    user = ensure_user_can_cancel_task(completed_task)
    params = {
      status: Constants.TASK_STATUSES.cancelled,
      instructions: format_cancellation_reason(completed_task.type, updated_at)
    }
    update_from_params(params, user)
  end

  private

  # Ensure create is called on a descendant mail task and not directly on the HearingRequestMailTask class
  def verify_request_type_designated
    if self.class == HearingRequestMailTask
      fail Caseflow::Error::InvalidTaskTypeOnTaskCreate, task_type: type
    end
  end

  # Purpose: Associated appeal has an upcoming hearing with an open status
  # Params: None
  # Return: Returns a boolean if the appeal has an upcoming hearing
  def hearing_scheduled_and_awaiting_disposition?
    return false unless open_hearing

    # Ensure associated hearing is not scheduled for the past
    !open_hearing.scheduled_for_past?
  end

  # Purpose: Gives the latest active hearing task
  # Params: None
  # Return: The latest active hearing task
  def active_schedule_hearing_task
    appeal.tasks.of_type(ScheduleHearingTask.name).active.first
  end

  # ChangeHearingDispositionTask is a subclass of AssignHearingDispositionTask
  ASSIGN_HEARING_DISPOSITION_TASKS = [
    AssignHearingDispositionTask.name,
    ChangeHearingDispositionTask.name
  ].freeze

  # Purpose: Gives the latest active assign hearing disposition task
  # Params: None
  # Return: The latest active assign hearing disposition task
  def open_assign_hearing_disposition_task
    @open_assign_hearing_disposition_task ||= appeal.tasks.of_type(ASSIGN_HEARING_DISPOSITION_TASKS).open&.first
  end

  # Purpose: Sets the previous hearing's disposition
  # Params: None
  # Return: Returns a boolean for if the hearing has been updated
  def update_hearing(hearing_hash)
    if open_hearing.is_a?(LegacyHearing)
      open_hearing.update_caseflow_and_vacols(hearing_hash)
    else
      open_hearing.update(hearing_hash)
    end
  end

  # Purpose: Completes the Mail task assigned to the MailTeam and the one for HearingAdmin
  # Params: user - The current user object
  #         params - The attributes needed to update the instructions specific to HPR/HWR
  # Return: Boolean for if the tasks have been updated
  def update_self_and_parent_mail_task(user:, params:)
    updated_instructions = format_instructions_on_completion(params)
    begin
      update!(
        completed_by: user,
        status: Constants.TASK_STATUSES.completed,
        instructions: updated_instructions
      )
    rescue StandardError => error
      log_error(error)
    end
    update_parent_status
  end

  # Purpose: If hearing postponed/withdrawn by a member of HearingAdminTeam, return that user. Otherwise, in
  #          the case that hearing disposition is changed by HearingChangeDispositionJob, current_user is
  #          system_user and will not have permission to call Task#update_from_params. Instead, return a user
  #          with with HearingAdmin privileges.
  #
  # Params: completed_task - Task object of task through which heairng was postponed
  def ensure_user_can_cancel_task(completed_task)
    current_user = RequestStore[:current_user]

    return current_user if current_user&.in_hearing_admin_team?

    completed_task.hearing.updated_by
  end

  # Purpose: Format context to be appended to HPR/HWR mail tasks instructions upon task cancellation
  #
  # Params: task_name - string of name of completed task through which hearing was postponed/withdrawn
  #         updated_at - datetime when the task was completed
  #
  # Return: String to be submitted in instructions field of task
  def format_cancellation_reason(task_name, updated_at)
    request_action = is_a?(HearingPostponementRequestMailTask) ? "postponed" : "withdrawn"
    formatted_date = updated_at.strftime("%m/%d/%Y")

    "##### REASON FOR CANCELLATION:\n" \
    "Hearing #{request_action} when #{task_name} was completed on #{formatted_date}"
  end
end
