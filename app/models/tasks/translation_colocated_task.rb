# frozen_string_literal: true

class TranslationColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.translation
  end

  # def self.default_assignee(_parent)
  #   LitigationSupport.singleton
  # end
end
