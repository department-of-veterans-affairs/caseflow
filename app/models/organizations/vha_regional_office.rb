# frozen_string_literal: true

class VhaRegionalOffice < Organization
  def can_receive_task?(_task)
    false
  end
end
