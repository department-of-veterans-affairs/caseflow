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
    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.cancelled
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # original method defined in app/models/hearings/forms/hearing_update_form.rb
  def update_hearing
    super_return_value = super
    if hearing_updates[:disposition] == Constants.HEARING_DISPOSITION_TYPES.cancelled
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # original method defined in app/models/vacols/case_hearing.rb
  def update_hearing!(hearing_info)
    super_return_value = super
    if hearing_info[:disposition].to_s == "C"
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end
end
