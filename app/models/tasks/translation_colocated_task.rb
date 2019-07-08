# frozen_string_literal: true

class TranslationColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.translation
  end

  def available_actions_with_conditions(core_actions)
    core_actions = super(core_actions)
    if appeal.is_a?(LegacyAppeal)
      return legacy_translation_actions(core_actions)
    else
      return ama_translation_actions(core_actions)
    end
  end

  def vacols_location
    LegacyAppeal::LOCATION_CODES[:translation]
  end
end
