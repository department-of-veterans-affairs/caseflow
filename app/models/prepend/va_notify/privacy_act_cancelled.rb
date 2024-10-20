# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Completed
module PrivacyActCancelled
  extend AppellantNotification

  PRIVACY_ACT_TASKS = %w[FoiaColocatedTask PrivacyActTask HearingAdminActionFoiaPrivacyRequestTask
                         PrivacyActRequestMailTask FoiaRequestMailTask].freeze
  # Purpose: Abstract method that is called by #update_appeal_state_on_status_change.
  # This method is prepended in app/models/prepend/va_notify/privacy_act_cancelled.rb.
  # This method will update the correlated record in the 'Appeal States' table when a privacy act
  # task is cancelled.8.
  #
  # Params: NONE
  #
  # Response: The Appeal State record correlated to the current task's appeal will be updated.
  def update_appeal_state_when_privacy_act_cancelled
    if PRIVACY_ACT_TASKS.include?(type) &&
       !PRIVACY_ACT_TASKS.include?(parent&.type) &&
       status == Constants.TASK_STATUSES.cancelled
      appeal.appeal_state.privacy_act_cancelled_appeal_state_update_action!
    end
  end
end
