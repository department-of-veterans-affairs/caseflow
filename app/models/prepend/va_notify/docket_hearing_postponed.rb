# frozen_string_literal: true

# Module to notify appellant if Hearing is Postponed
# For postponed hearings from daily docket page for AMA  appeals
module DocketHearingPostponed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Postponement of hearing"
  # rubocop:enable all

  rescue_from AppealTypeNotImplementedError do |exception|
    Rails.logger.error(exception)
    Rails.logger.error("Invalid Appeal Type for DocketHearingPostponed")
  end

  # AMA Hearing Postponed from the Daily Docket
  # original method defined in app/models/hearings/forms/hearing_update_form.rb
  def update_hearing
    super_return_value = super
    if hearing_updates[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed
      AppellantNotification.appeal_mapper(hearing.appeal.id, hearing.appeal.class.to_s, "hearing_postponed")
      AppellantNotification.notify_appellant(hearing.appeal, @@template_name)
    end
    super_return_value
  end
end
