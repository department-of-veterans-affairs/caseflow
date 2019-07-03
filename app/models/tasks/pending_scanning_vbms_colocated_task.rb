# frozen_string_literal: true

class PendingScanningVbmsColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.pending_scanning_vbms
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
