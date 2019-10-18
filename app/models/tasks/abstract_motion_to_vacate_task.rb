# frozen_string_literal: true

class AbstractMotionToVacateTask < GenericTask
  def hide_from_task_snapshot
    true
  end
end
