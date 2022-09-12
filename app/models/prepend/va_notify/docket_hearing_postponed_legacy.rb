# frozen_string_literal: true

# Module to notify appellant if Hearing is Postponed
# For postponed hearings from daily docket page for Legacy appeals
module DocketHearingPostponedLegacy
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Postponement of hearing"
  # rubocop:enable all

  # original method defined in app/models/vacols/case_hearing.rb
  def update_hearing!(hearing_info)
    super_return_value = super
    if hearing_info[:disposition].to_s == "P"
      appeal = LegacyAppeal.find_by(vacols_id: folder_nr)
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end
end
