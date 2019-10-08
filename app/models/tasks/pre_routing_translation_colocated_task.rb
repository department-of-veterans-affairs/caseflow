# frozen_string_literal: true

class PreRoutingTranslationColocatedTask < PreRoutingColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.translation
  end
end
