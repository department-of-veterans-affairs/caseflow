# frozen_string_literal: true

class JudgeQueue < GenericQueue
  def tasks
    super.active.where(type: JudgeAssignTask.name)
  end
end
