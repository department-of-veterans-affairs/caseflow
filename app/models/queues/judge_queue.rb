# frozen_string_literal: true

class JudgeQueue < GenericQueue
  def tasks
    super.active.not_correspondence.where(type: JudgeAssignTask.name)
  end
end
