# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Appeal decision mailed"

  CONTESTED_CLAIM = "#{@@template_name} (Contested claims)"
  NON_CONTESTED_CLAIM = "#{@@template_name} (Non-contested claims)"
  # rubocop:enable all

  # Purpose: Adds VA Notify integration to the original method defined in app/models/decision_document.rb
  #
  # Params: none
  #
  # Response: returns true if successfully processed, returns false if not successfully processed (will not notify)
  def process!(mail_package = nil)
    super_return_value = super
    if processed?
      AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "decision_mailed")
      case appeal_type
      when "Appeal"
        template = appeal.contested_claim? ? CONTESTED_CLAIM : NON_CONTESTED_CLAIM
      when "LegacyAppeal"
        template = appeal.contested_claim ? CONTESTED_CLAIM : NON_CONTESTED_CLAIM
      end
      AppellantNotification.notify_appellant(appeal, template)
    end
    super_return_value
  end
end
