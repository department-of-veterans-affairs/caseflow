# frozen_string_literal: true

class TranslationColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.translation
  end

  def available_actions(core_actions)
    core_actions = super(core_actions)
    if appeal.is_a?(LegacyAppeal)
      return legacy_translation_actions(core_actions)
    else
      return ama_translation_actions(core_actions)
    end
  end

  private

  def ama_translation_actions(core_actions)
    core_actions.push(Constants.TASK_ACTIONS.SEND_TO_TRANSLATION.to_h)
    core_actions
  end

  def legacy_translation_actions(actions)
    send_to_team = Constants.TASK_ACTIONS.SEND_TO_TEAM.to_h
    send_to_team[:label] = format(COPY::COLOCATED_ACTION_SEND_TO_TEAM, Constants.CO_LOCATED_ADMIN_ACTIONS.translation)
    actions.unshift(send_to_team)
  end

  def vacols_location
    LegacyAppeal::LOCATION_CODES[:translation]
  end
end
