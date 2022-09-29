# frozen_string_literal: true

# Module to notify appellant if Hearing is Postponed
module HearingPostponed
  extend AppellantNotification
  # rubocop:disable Style/ClassVars
  @@template_name = "Postponement of hearing"
  # rubocop:enable Style/ClassVars

  # Legacy Appeals
  # original method defined in app/models/legacy_hearing.rb
  def update_caseflow_and_vacols(hearing_hash)
    super

    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed
      appeal = LegacyAppeal.find(appeal_id)
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end

  # original method defined in app/models/tasks/assign_hearing_disposition_task.rb
  def update_hearing(hearing_hash)
    super

    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed && appeal.is_a?(Appeal)
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end
end
