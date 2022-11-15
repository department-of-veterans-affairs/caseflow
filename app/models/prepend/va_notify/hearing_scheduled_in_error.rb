# frozen_string_literal: true

# Module to track status of appeal if hearing is scheduled in error
# This module will update a row in the appeal_states and consequently
# insert a new row in the caseflow_audit.appeal_states_audit table
module HearingScheduledInError
  extend AppellantNotification

  # Purpose: Inserts or updates a row in the appeal_states table
  #
  # Params: { disposition: Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error, hearing_notes: "OPTIONAL" }
  #
  # Response: Return value of original method defined in app/models/tasks/assign_hearing_disposition_task.rb
  def update_hearing_disposition_and_notes(payload_values)
    super_return_value = super
    MetricsService.record("Updating VSO_IHP_PENDING column in Appeal States Table to FALSE for #{appeal.class.to_s} ID #{appeal.id}",
                            service: :queue,
                            name: "AppellantNotification.appeal_mapper") do
            # APPEAL MAPPER METHOD
      end
    super_return_value
  end
end
