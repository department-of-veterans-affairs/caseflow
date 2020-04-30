# frozen_string_literal: true

class JudgeQueue < GenericQueue
  def tasks
    super.active
  end
end
