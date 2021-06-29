# frozen_string_literal: true

class OpenTasksWithClosedAtChecker < DataIntegrityChecker
  def call
    suspect_tasks = open_tasks_with_closed_at_defined
    if suspect_tasks.count > 0
      add_to_report "#{suspect_tasks.count} open " + "Task".pluralize(suspect_tasks.count) + " with a closed_at value"
      add_to_report "Verify data error with `Task.open.where.not(closed_at: nil)`"
      add_to_report "These tasks likely were manually re-opened and should have closed_at set to NULL"
    end
    suspect_tasks = open_tasks_with_closed_parent
    if suspect_tasks.count > 0
      add_to_report "#{suspect_tasks.count} open " +
                    "Task".pluralize(suspect_tasks.count) +
                    " with a closed parent Task"
      add_to_report "Verify with `Task.where(id: [#{suspect_tasks.pluck(:id).join(',')}])`"
    end
  end

  def slack_channel
    "#appeals-echo"
  end

  private

  def open_tasks_with_closed_at_defined
    Task.open.where.not(closed_at: nil)
  end

  def open_tasks_with_closed_parent
    Task.open.joins(:parent).includes(:parent).where.not(parents_tasks: { closed_at: nil })
  end
end
