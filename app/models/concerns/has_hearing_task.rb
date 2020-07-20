# frozen_string_literal: true

module HasHearingTask
  extend ActiveSupport::Concern

  included do
    has_one :hearing_task_association,
            -> { includes(:hearing_task).where(tasks: { status: Task.open_statuses }) },
            as: :hearing
  end

  def hearing_task
    hearing_task_association&.hearing_task
  end

  def hearing_task?
    !hearing_task_association.nil?
  end

  def disposition_task
    if hearing_task?
      hearing_task_association.hearing_task.children.detect { |child| child.type == AssignHearingDispositionTask.name }
    end
  end

  def disposition_task_in_progress
    disposition_task ? disposition_task.open_with_no_children? : false
  end

  def disposition_editable
    disposition_task_in_progress || !hearing_task?
  end
end
