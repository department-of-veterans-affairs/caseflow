# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Appeal decision mailed"
  # rubocop:enable all

  # Purpose: Adds VA Notify integration to the original method defined in app/models/decision_document.rb
  #
  # Params: none
  #
  # Response: returns true if successfully processed, returns false if not successfully processed (will not notify)
  def process!
    super_return_value = super
    if processed?
      AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "decision_mailed")
      case appeal_type
      when "Appeal"
        template = appeal.contested_claim? ? "#{@@template_name} (Contested claims)" : "#{@@template_name} (Non-contested claims)"
        AppellantNotification.notify_appellant(appeal, template)
      when "LegacyAppeal"
        template = appeal.contested_claim ? "#{@@template_name} (Contested claims)" : "#{@@template_name} (Non-contested claims)"
        AppellantNotification.notify_appellant(appeal, template)
      end
    end
    super_return_value
  end
end
