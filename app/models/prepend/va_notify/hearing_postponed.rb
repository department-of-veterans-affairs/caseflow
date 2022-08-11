# frozen_string_literal: true

# Module to notify appellant if Hearing is Postponed
module HearingPostponed
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  def update_hearing(hearing_hash)
    super
    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
