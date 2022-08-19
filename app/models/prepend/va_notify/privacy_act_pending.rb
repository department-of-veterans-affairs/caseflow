# frozen_string_literal: true

# Module to notify appellant if Privacy Act Request is Pending
module PrivacyActPending
  extend AppellantNotification
  # rubocop:disable all
  @@template_name = self.to_s
  # rubocop:enable all

  # for foiacolocatedtasks
  def create_privacy_act_task
    # original method defined in app/models/tasks/foia_colocated_task.rb
    super
    AppellantNotification.notify_appellant(appeal, @@template_name)
  end

  # for foia/privacy act mail tasks
  # original method defined in app/models/task.rb
  def create_twin_of_type(params)
    super
    if type == "PrivacyActRequestMailTask" || type == "FoiaRequestMailTask"
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end

  # for HearingAdminFoiaPrivacyRequestTask/PrivacyActTask
  # original method defined in app/models/task.rb
  def create_child_task(parent, current_user, params)
    super
    if ("PrivacyActTask".include?(params[:type]) && params[:assigned_to_type].include?("Organization")) ||
       ("HearingAdminActionFoiaPrivacyRequestTask".include?(params[:type]) && parent.type == "ScheduleHearingTask")
      AppellantNotification.notify_appellant(parent.appeal, @@template_name)
    end
  end
end
