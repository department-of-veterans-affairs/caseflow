# frozen_string_literal: true

class TranslationColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.translation
  end
end
