# frozen_string_literal: true

class PendingScanningVbmsColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.pending_scanning_vbms
  end
end
