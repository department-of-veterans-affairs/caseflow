# frozen_string_literal: true

# Task created after an appellant no-shows for a hearing. Gives the hearings team the options to decide how to handle
# the no-show hearing after the judge indicates that the appellant no-showed.
class NoShowHearingTask < GenericTask
  before_validation :set_assignee

  def reschedule_hearing
    update!(status: Constants.TASK_STATUSES.completed)
    RootTask.create_hearing_schedule_task!(appeal, root_task)
  end

  private

  def set_assignee
    self.assigned_to = HearingAdmin.singleton
  end
end
