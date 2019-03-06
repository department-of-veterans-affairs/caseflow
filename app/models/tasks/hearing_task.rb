# frozen_string_literal: true

##
# A task used to track all related hearing subtasks.
# A hearing task is associated with a hearing record in Caseflow and might have several child tasks to resolve
# in order to schedule a hearing, hold it, and mark the disposition.

class HearingTask < GenericTask
  has_one :hearing_task_association

  private

  def update_status_if_children_tasks_are_complete
    unique_child_types = children&.map(&:type)&.uniq || []
    if unique_child_types.count == 1 && unique_child_types.first == "DispositionTask"
      unique_child_status = children&.map(&:status)&.uniq&.first
      return update!(status: :cancelled) if unique_child_status == Constants.TASK_STATUSES.cancelled
    end

    super
  end
end
