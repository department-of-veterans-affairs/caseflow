# frozen_string_literal: true

class StayedAppealColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.stayed_appeal
  end
end
