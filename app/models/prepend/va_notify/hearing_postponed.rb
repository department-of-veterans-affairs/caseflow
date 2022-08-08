# frozen_string_literal: true

# Module to notify appellant if Hearing is Postponed
module HearingPostponed
  @@template_name = name.split("::")[1]
  def postpone!
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end

  def mark_hearing_with_disposition(payload_values:, instructions: nil)
    super
    hearing = Hearing.find_by(appeal_id: appeal.id)
    if hearing.disposition == Constants.HEARING_DISPOSITION_TYPES.postponed
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
