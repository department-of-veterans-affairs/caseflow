# frozen_string_literal: true

class IhpColocatedTask < ColocatedTask
  include CavcAdminActionConcern

  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.ihp
  end
end
