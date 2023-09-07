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

  private

  # Ensure create is called on a descendant mail task and not directly on the HearingRequestMailTask class
  def verify_request_type_designated
    if self.class == HearingRequestMailTask
      fail Caseflow::Error::InvalidTaskTypeOnTaskCreate, task_type: type
    end
  end

  def active_schedule_hearing_task?
    appeal.tasks.where(type: ScheduleHearingTask.name).active.any?
  end

  def open_assign_hearing_disposition_task?
    # ChangeHearingDispositionTask is a subclass of AssignHearingDispositionTask
    disposition_task_names = [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name]
    open_task = appeal.tasks.where(type: disposition_task_names).open.first

    return false unless open_task&.hearing

    # Ensure hearing associated with AssignHearingDispositionTask is not scheduled in the past
    !open_task.hearing.scheduled_for_past?
  end
end
