# frozen_string_literal: true

class PreRoutingFoiaColocatedTask < PreRoutingColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.foia
  end
end
