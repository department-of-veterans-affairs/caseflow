# frozen_string_literal: true

class UnaccreditedRepColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.unaccredited_rep
  end
end
