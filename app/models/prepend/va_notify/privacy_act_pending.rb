# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Pending
module PrivacyActPending
  extend AppellantNotification

  PRIVACY_ACT_TASKS = %w[FoiaColocatedTask PrivacyActTask HearingAdminActionFoiaPrivacyRequestTask
                         PrivacyActRequestMailTask FoiaRequestMailTask].freeze

  # for foiacolocatedtasks
  def create_privacy_act_task
    # original method defined in app/models/tasks/foia_colocated_task.rb
    super_return_value = super
    AppellantNotification.notify_appellant(appeal, Constants.EVENT_TYPE_FILTERS.privacy_act_request_pending)
    super_return_value
  end

  # for foia/privacy act mail tasks
  # original method defined in app/models/mail_task.rb
  def create_twin_of_type(params)
    super_return_value = super
    if params[:type] == "PrivacyActRequestMailTask" || params[:type] == "FoiaRequestMailTask"
      AppellantNotification.notify_appellant(appeal, Constants.EVENT_TYPE_FILTERS.privacy_act_request_pending)
    end
    super_return_value
  end

  # for HearingAdminFoiaPrivacyRequestTask/PrivacyActTask
  # original method defined in app/models/task.rb
  def create_child_task(parent, current_user, params)
    super_return_value = super
    if (params[:type] == "PrivacyActTask" && params[:assigned_to_type].include?("Organization")) ||
       (params[:type] == "HearingAdminActionFoiaPrivacyRequestTask" && parent.type == "ScheduleHearingTask")
      AppellantNotification.notify_appellant(parent.appeal,
                                             Constants.EVENT_TYPE_FILTERS.privacy_act_request_pending)
    end
    super_return_value
  end

  def update_appeal_state_when_privacy_act_created
    if PRIVACY_ACT_TASKS.include?(type) && !PRIVACY_ACT_TASKS.include?(parent&.type)
      appeal.appeal_state.privacy_act_pending_appeal_state_update_action!
    end
  end
end
