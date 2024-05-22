# frozen_string_literal: true

# Module to notify appellant if Hearing is Scheduled
module HearingScheduled
  extend AppellantNotification

  def create_hearing(task_values)
    # original method defined in app/models/tasks/schedule_hearing_task.rb
    super_return_value = super
    AppellantNotification.notify_appellant(appeal, Constants.EVENT_TYPE_FILTERS.hearing_scheduled)
    super_return_value
  end

  # Purpose: Callback method when a hearing is created to also update appeal_states table
  #
  # Params: none
  #
  # Response: none
  def update_appeal_states_on_hearing_scheduled
    appeal.appeal_state.hearing_scheduled_appeal_state_update_action!
  end
end
