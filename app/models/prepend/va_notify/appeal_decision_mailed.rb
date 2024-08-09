# frozen_string_literal: true

# Module to notify appellant if an Appeal Decision is Mailed
module AppealDecisionMailed
  extend AppellantNotification

  CONTESTED_CLAIM = Constants.EVENT_TYPE_FILTERS.appeal_decision_mailed_contested_claims
  NON_CONTESTED_CLAIM = Constants.EVENT_TYPE_FILTERS.appeal_decision_mailed_non_contested_claims

  # Purpose: Adds VA Notify integration to the original method defined in app/models/decision_document.rb
  #
  # Params: none
  #
  # Response: returns true if successfully processed, returns false if not successfully processed (will not notify)
  def process!(contested, mail_package = nil)
    super_return_value = super
    if processed?
      appeal.appeal_state.decision_mailed_appeal_state_update_action!
      template = contested ? CONTESTED_CLAIM : NON_CONTESTED_CLAIM
      AppellantNotification.notify_appellant(appeal, template)
    end
    super_return_value
  end
end
