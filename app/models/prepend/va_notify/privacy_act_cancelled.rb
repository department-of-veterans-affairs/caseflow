# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Completed
module PrivacyActCancelled
  extend AppellantNotification

  PRIVACY_ACT_TASKS = %w[FoiaColocatedTask PrivacyActTask
                         HearingAdminFoiaPrivacyRequestTask PrivacyActRequestMailTask FoiaRequestMailTask].freeze

  def update_appeal_state_when_privacy_act_cancelled
    byebug
    if PRIVACY_ACT_TASKS.include?(type) &&
       !PRIVACY_ACT_TASKS.include?(parent&.type) &&
       status == Constants.TASK_STATUSES.cancelled
      MetricsService.record("Updating PRIVACY_ACT_PENDING column in Appeal States Table to FALSE "\
        "for #{appeal.class} ID #{appeal.id}".yellow,
                            service: nil,
                            name: "AppellantNotification.appeal_mapper") do
        AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "privacy_act_cancelled")
      end
    end
  end
end
