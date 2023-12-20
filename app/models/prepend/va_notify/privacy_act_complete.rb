# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Completed
module PrivacyActComplete
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Privacy Act request complete"
  # rubocop:enable all
  PRIVACY_ACT_TASKS = %w[FoiaColocatedTask PrivacyActTask HearingAdminActionFoiaPrivacyRequestTask
                         PrivacyActRequestMailTask FoiaRequestMailTask].freeze

  def update_status_if_children_tasks_are_closed(child_task)
    # original method defined in app/models/task.rb
    super_return_value = super
    if ((type.to_s.include?("Foia") && !parent&.type.to_s.include?("Foia")) ||
       (type.to_s.include?("PrivacyAct") && !parent&.type.to_s.include?("PrivacyAct"))) &&
       status == Constants.TASK_STATUSES.completed
      # appellant notification call
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # original method defined in app/models/task.rb
  # for Privacy Act Tasks that are only assigned to an Organization
  def update_with_instructions(params)
    super_return_value = super
    if type.to_s == "PrivacyActTask" && assigned_to_type == "Organization" &&
       status == Constants.TASK_STATUSES.completed
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  def update_appeal_state_when_privacy_act_complete
    if PRIVACY_ACT_TASKS.include?(type) &&
       !PRIVACY_ACT_TASKS.include?(parent&.type) &&
       status == Constants.TASK_STATUSES.completed
      MetricsService.record("updating PRIVACY_ACT_COMPLETE column to true and
                             PRIVACY_ACT_PENDING column in Appeal States Table to FALSE "\
        "for #{appeal.class} ID #{appeal.id} if no pending Privacy Acts exist",
                            service: nil,
                            name: "AppellantNotification.appeal_mapper") do
        AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "privacy_act_complete")
      end
    end
  end
end
