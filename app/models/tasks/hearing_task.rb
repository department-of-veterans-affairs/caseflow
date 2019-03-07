# frozen_string_literal: true

##
# A task used to track all related hearing subtasks.
# A hearing task is associated with a hearing record in Caseflow and might have several child tasks to resolve
# in order to schedule a hearing, hold it, and mark the disposition.

class HearingTask < GenericTask
  has_one :hearing_task_association

  private

  def update_status_if_children_tasks_are_complete
    if children.select(&:active?).empty?
      return update!(status: :cancelled) if children.select { |c| c.type == DispositionTask.name && c.cancelled? }.any?
    end

    super
  end
end
