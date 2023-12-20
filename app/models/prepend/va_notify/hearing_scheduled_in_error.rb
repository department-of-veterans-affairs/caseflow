# frozen_string_literal: true

# Module to track status of appeal if hearing is scheduled in error
# This module will update a row in the appeal_states and consequently
# insert a new row in the caseflow_audit.appeal_states_audit table
module HearingScheduledInError
  extend AppellantNotification

  # Purpose: Callback method when a hearing updates to also update appeal_states table
  #
  # Params: none
  #
  # Response: none
  def update_appeal_states_on_hearing_scheduled_in_error
    if is_a?(LegacyHearing)
      if VACOLS::CaseHearing.find_by(hearing_pkseq: vacols_id)&.hearing_disp == "E"
        MetricsService.record("Updating SCHEDULED_IN_ERROR in Appeal States Table for #{appeal.class} ID #{appeal.id}",
                              name: "AppellantNotification.appeal_mapper") do
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "scheduled_in_error")
        end
      end
    elsif is_a?(Hearing)
      if disposition == Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
        MetricsService.record("Updating SCHEDULED_IN_ERROR in Appeal States Table for #{appeal.class} ID #{appeal.id}",
                              name: "AppellantNotification.appeal_mapper") do
          AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "scheduled_in_error")
        end
      end
    end
  end
end
