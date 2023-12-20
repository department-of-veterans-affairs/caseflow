# frozen_string_literal: true

# Module to notify appellant if Hearing is Withdrawn
module HearingWithdrawn
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Withdrawal of hearing"
  # rubocop:enable all

  # Legacy OR AMA Hearing Withdrawn from Queue
  # original method defined in app/models/tasks/assign_hearing_disposition_task.rb
  def update_hearing(hearing_hash)
    super_return_value = super
    if hearing_hash[:disposition] == Constants.HEARING_DISPOSITION_TYPES.cancelled && appeal.class.to_s == "Appeal"
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # Legacy Hearing Withdrawn from the Daily Docket
  # original method defined in app/models/legacy_hearing.rb
  def update_caseflow_and_vacols(hearing_hash)
    original_disposition = vacols_record.hearing_disp
    super_return_value = super
    new_disposition = vacols_record.hearing_disp
    if cancelled? && original_disposition != new_disposition
      appeal = LegacyAppeal.find(appeal_id)
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # Purpose: Callback method when a hearing updates to also update appeal_states table
  #
  # Params: none
  #
  # Response: none
  def update_appeal_states_on_hearing_withdrawn
    if is_a?(LegacyHearing)
      if VACOLS::CaseHearing.find_by(hearing_pkseq: vacols_id)&.hearing_disp == "C"
        MetricsService.record("Updating HEARING_WITHDRAWN in Appeal States Table for #{appeal.class} ID #{appeal.id}",
                              name: "AppellantNotification.appeal_mapper") do
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "hearing_withdrawn")
        end
      end
    elsif is_a?(Hearing)
      if disposition == Constants.HEARING_DISPOSITION_TYPES.cancelled
        MetricsService.record("Updating HEARING_WITHDRAWN in Appeal States Table for #{appeal.class} ID #{appeal.id}",
                              name: "AppellantNotification.appeal_mapper") do
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "hearing_withdrawn")
        end
      end
    end
  end
end
