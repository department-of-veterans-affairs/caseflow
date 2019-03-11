# frozen_string_literal: true

# Task created after an appellant no-shows for a hearing. Gives the hearings team the options to decide how to handle
# the no-show hearing after the judge indicates that the appellant no-showed.
class NoShowHearingTask < GenericTask
  before_validation :set_assignee

  private

  def set_assignee
    self.assigned_to = assigned_to.nil? ? HearingAdmin.singleton : assigned_to
  end
end
