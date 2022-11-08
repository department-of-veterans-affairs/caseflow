# frozen_string_literal: true

# Module to track status of appeal if hearing is scheduled in error
module HearingScheduledInError
  extend AppellantNotification

  def update_hearing_disposition_and_notes(payload_values)
    # original method defined in app/models/tasks/assign_hearing_disposition_task.rb
    super_return_value = super

    # APPEAL MAPPER METHOD
    # AppellantNotification.notify_appellant(appeal, @@template_name)
    super_return_value
  end
end

# This method is only used when disposition is changed to scheduled in error.
# If AC are correct and both reschedule immediately and send back to schedule veteran list are valid triggers then this method will work and cover both cases
# Currently both options give AssignHearingDispositionTask a cancelled status and create a new HearingTask
# ONLY send back to schedule veteran list will create a ScheduleHearingTask
