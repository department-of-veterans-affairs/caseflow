# frozen_string_literal: true

class FoiaColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.foia
  end

  def self.default_assignee
    PrivacyTeam.singleton
  end
end
