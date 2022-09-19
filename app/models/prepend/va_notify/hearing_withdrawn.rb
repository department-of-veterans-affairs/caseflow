# frozen_string_literal: true

# Module to notify appellant if Hearing is Withdrawn
module HearingWithdrawn
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Withdrawal of hearing"
  # rubocop:enable all

  # original method defined in app/models/tasks/assign_hearing_disposition_task.rb
  def update_hearing(hearing_hash)
    super_return_value = super
    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.cancelled && appeal.class.to_s == "Appeal"
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # original method defined in app/models/legacy_hearing.rb
  def update_caseflow_and_vacols(hearing_hash)
    super_return_value = super
    if cancelled?
      appeal = LegacyAppeal.find(appeal_id)
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end
end
