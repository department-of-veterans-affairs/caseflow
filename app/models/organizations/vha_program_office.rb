# frozen_string_literal: true

class VhaProgramOffice < Organization
  def can_receive_task?(_task)
    false
  end
end
