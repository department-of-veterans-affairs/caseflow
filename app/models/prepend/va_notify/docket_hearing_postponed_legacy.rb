# frozen_string_literal: true

# Module to notify appellant if Hearing is Postponed
# For postponed hearings from daily docket page for Legacy appeals
module DocketHearingPostponedLegacy
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Postponement of hearing"
  # rubocop:enable all

  # original method defined in app/models/legacy_hearing.rb
  def update_caseflow_and_vacols(hearing_hash)
    super_return_value = super
    if postponed?
      appeal = LegacyAppeal.find(appeal_id)
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end
end
