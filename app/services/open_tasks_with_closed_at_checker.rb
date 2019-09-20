# frozen_string_literal: true

class OpenTasksWithClosedAtChecker < DataIntegrityChecker
  def call
    suspect_tasks = open_tasks_with_closed_at_defined
    if suspect_tasks.count > 0
      add_to_report "#{suspect_tasks.count} open Task(s) with a closed_at value"
      add_to_report "Verify data error with `Task.open.where.not(closed_at: nil)`"
      add_to_report "These tasks likely were manually re-opened and should have closed_at set to NULL"
    end
  end

  private

  def open_tasks_with_closed_at_defined
    Task.open.where.not(closed_at: nil)
  end
end
