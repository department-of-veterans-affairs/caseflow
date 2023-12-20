# frozen_string_literal: true

class ExtensionColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.extension
  end
end
