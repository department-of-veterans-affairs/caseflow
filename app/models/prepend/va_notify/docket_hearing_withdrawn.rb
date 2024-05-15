# frozen_string_literal: true

# Module to notify appellant if Hearing is Withdrawn
# For withdrawn hearings from daily docket page for AMA appeals
module DocketHearingWithdrawn
  extend AppellantNotification

  # AMA Hearing Withdrawn from the Daily Docket
  # original method defined in app/models/hearings/forms/hearing_update_form.rb
  def update_hearing
    super_return_value = super
    if hearing_updates[:disposition] == Constants.HEARING_DISPOSITION_TYPES.cancelled
      AppellantNotification.notify_appellant(hearing.appeal, Constants.EVENT_TYPE_FILTERS.withdrawal_of_hearing)
    end
    super_return_value
  end
end
