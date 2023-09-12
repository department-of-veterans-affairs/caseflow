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

  # Purpose: Determines if there is an open hearing
  # Params: None
  # Return: The hearing if one exists
  def open_hearing
    @open_hearing ||= open_assign_hearing_disposition_task&.hearing
  end

  # Purpose: Gives the latest hearing task
  # Params: None
  # Return: The hearing task
  def hearing_task
    @hearing_task ||= open_hearing&.hearing_task || active_schedule_hearing_task.parent
  end

  private

  # Ensure create is called on a descendant mail task and not directly on the HearingRequestMailTask class
  def verify_request_type_designated
    if self.class == HearingRequestMailTask
      fail Caseflow::Error::InvalidTaskTypeOnTaskCreate, task_type: type
    end
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

  # Purpose: Associated appeal has an upcoming hearing with an open status
  # Params: None
  # Return: Returns a boolean if the appeal has an upcoming hearing
  def hearing_scheduled_and_awaiting_disposition?
    return false unless open_hearing

    # Ensure associated hearing is not scheduled for the past
    !open_hearing.scheduled_for_past?
  end

  # Purpose: Deletes the old scheduled virtual hearings
  # Params: None
  # Return: Returns nil
  def clean_up_virtual_hearing
    if open_hearing.virtual?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
    end
  end
end
