# frozen_string_literal: true

class OtherColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.other
  end
end
