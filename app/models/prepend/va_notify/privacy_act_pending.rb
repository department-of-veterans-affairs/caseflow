# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Pending
module PrivacyActPending
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = "Privacy Act request pending"
  # rubocop:enable all
  PRIVACY_ACT_TASKS = %w[FoiaColocatedTask PrivacyActTask HearingAdminActionFoiaPrivacyRequestTask
                         PrivacyActRequestMailTask FoiaRequestMailTask].freeze

  # for foiacolocatedtasks
  def create_privacy_act_task
    # original method defined in app/models/tasks/foia_colocated_task.rb
    super_return_value = super
    AppellantNotification.notify_appellant(appeal, @@template_name)
    super_return_value
  end

  # for foia/privacy act mail tasks
  # original method defined in app/models/mail_task.rb
  def create_twin_of_type(params)
    super_return_value = super
    if params[:type] == "PrivacyActRequestMailTask" || params[:type] == "FoiaRequestMailTask"
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
    super_return_value
  end

  # for HearingAdminFoiaPrivacyRequestTask/PrivacyActTask
  # original method defined in app/models/task.rb
  def create_child_task(parent, current_user, params)
    super_return_value = super
    if (params[:type] == "PrivacyActTask" && params[:assigned_to_type].include?("Organization")) ||
       (params[:type] == "HearingAdminActionFoiaPrivacyRequestTask" && parent.type == "ScheduleHearingTask")
      AppellantNotification.notify_appellant(parent.appeal, @@template_name)
    end
    super_return_value
  end

  def update_appeal_state_when_privacy_act_created
    if PRIVACY_ACT_TASKS.include?(type) && !PRIVACY_ACT_TASKS.include?(parent&.type)
      MetricsService.record("Updating PRIVACY_ACT_PENDING column in Appeal States Table to TRUE and
                             PRIVACY_ACT_COMPLETE to FALSE "\
        "for #{appeal.class} ID #{appeal.id}",
                            service: nil,
                            name: "AppellantNotification.appeal_mapper") do
        AppellantNotification.appeal_mapper(appeal.id, appeal.class.to_s, "privacy_act_pending")
      end
    end
  end
end
