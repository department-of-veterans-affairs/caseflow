# frozen_string_literal: true

class Bva < Organization
  def self.singleton
    Bva.first || Bva.create(name: "Board of Veterans' Appeals", url: "bva")
  end

  def can_receive_task?(_task)
    false
  end
end
