# frozen_string_literal: true

class AbstractMotionToVacateTask < Task
  def hide_from_task_snapshot
    true
  end
end
