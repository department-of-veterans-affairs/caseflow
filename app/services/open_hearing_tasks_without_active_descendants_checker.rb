# frozen_string_literal: true

class OpenHearingTasksWithoutActiveDescendantsChecker < DataIntegrityChecker
  def call
    hearing_task_ids = ids_of_open_hearing_tasks_without_active_descendants
    build_report(hearing_task_ids)
  end

  private

  def ids_of_open_hearing_tasks_without_active_descendants
    HearingTask.open.select do |task|
      descendants_excluding_self = task.descendants - [task]
      descendants_excluding_self.map(&:active?).exclude?(true)
    end.map(&:id)
  end

  def build_report(hearing_task_ids)
    return if hearing_task_ids.empty?

    count = hearing_task_ids.count
    ids = hearing_task_ids.sort

    add_to_report "Found #{count} open #{'HearingTask'.pluralize(count)} with no active descendant tasks."
    add_to_report "The #{'hearing'.pluralize(count)} may not progress without manual intervention."
    add_to_report "`HearingTask.where(id: #{ids})`"
  end
end
