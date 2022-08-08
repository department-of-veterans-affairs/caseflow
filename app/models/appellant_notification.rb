# frozen_string_literal: true

# Module containing Aspect Overrides to Classes used to Track Statuses for Appellant Notification
module AppellantNotification

  class NoParticipantIdError < StandardError
    def initialize(appeal_id, message="There is no participant ID")
      super(message + " for #{appeal_id}")
    end
  end

  class NoClaimantError < StandardError
    def initialize(appeal_id, message="There is no claimant")
      super(message + " for #{appeal_id}")
    end
  end

  class NoAppealError < StandardError
    def initialize(appeal_id, message="There is no appeal")
      super(message + " for #{appeal_id}")
    end
  end

  def self.handle_errors(appeal)
    if appeal != nil
      # just rails logger
      appeal_id = appeal.id
      claimant = appeal.claimant
      participant_id = appeal.claimant&.participant_id
      if claimant == nil
        begin
          raise NoClaimantError.new(appeal_id)
        rescue => exception
          Rails.logger.error("#{exception.message}\n#{exception.backtrace.join("\n")}")
          exception.message
        end
      elsif participant_id == ""
        begin
          raise NoParticipantIdError.new(appeal_id)
        rescue => exception
          Rails.logger.error("#{exception.message}\n#{exception.backtrace.join("\n")}")
          exception.message
        end
      else
        "Success"
      end
    else
    # if appeal is null
      begin
        raise NoAppealError.new(appeal)
      rescue => error
        Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
        Raven.capture_exception(error, extra: { hearing_day_id: id, message: error.message })  
      end
    # rails logger and raven
    end
  end

  def self.notify_appellant(appeal, template_name, queue = Shoryuken::Client.queues(ActiveJob::Base.queue_name_prefix + '_send_notifications'))
    msg_bdy = create_payload(appeal, template_name)
    queue.send_message(msg_bdy)
  end

  def self.create_payload(appeal, template_name)
    status = AppellantNotification.handle_errors(appeal)
    appeal_id = appeal.id
    participant_id = appeal.claimant.participant_id
    appeal_type = appeal.class.to_s

    # find template_id from db using template name

    msg_bdy = {
      queue_url: "caseflow_development_send_notifications",
      message_body: "Notification for #{appeal_type}, #{template_name}",
      message_attributes: {
        :claimant => {
          value: participant_id,
          data_type: "String"
        },
        # "template_id" => {
        #   value: template_id,
        #   data_type: "String"
        # },
        :template_name => {
          value: template_name,
          data_type: "String"
        },
        :appeal_id => {
          value: appeal_id,
          data_type: "Integer"
        },
        :appeal_type => {
          value: appeal_type, #legacy vs ama
          data_type: "String"
        },
        :status => {
          value: status,
          data_type: "String"
        }
      }
    }
  end
  #Module to notify appellant when an appeal gets docketed
  module AppealDocketed
    @@template_name = self.name.split("::")[1]
    
    def create_tasks_on_intake_success!
      super
      distribution_task = DistributionTask.find_by(appeal_id: self.id)
      if (distribution_task)
        AppellantNotification.notify_appellant(self, @@template_name)
      end
    end

    def docket_appeal
      super
      AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end
  end

  #Module to notify appellant if an Appeal Decision is Mailed
  module AppealDecisionMailed
    @@template_name = self.name.split("::")[1]
    # Aspect for Legacy Appeals
    def complete_root_task!
      super
      AppellantNotification.notify_appellant(@appeal, @@template_name)
    end

    # Aspect for AMA Appeals
    def complete_dispatch_root_task!
      super
      AppellantNotification.notify_appellant(@appeal, @@template_name)
    end
  end

  #Module to notify appellant if Hearing is Scheduled
  module HearingScheduled
    @@template_name = self.name.split("::")[1]
    def create_hearing(task_values)
      super
      AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end
  end

  #Module to notify appellant if Hearing is Postponed
  module HearingPostponed
    @@template_name = self.name.split("::")[1]
    def postpone!
      super
      AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end

    def mark_hearing_with_disposition(payload_values:, instructions: nil)
      super
      hearing = Hearing.find_by(appeal_id: self.appeal.id)
      if (hearing.disposition == Constants.HEARING_DISPOSITION_TYPES.postponed)
        AppellantNotification.notify_appellant(self.appeal, @@template_name)
      end
    end
  end

  #Module to notify appellant if Hearing is Withdrawn
  module HearingWithdrawn
    @@template_name = self.name.split("::")[1]
    def cancel!
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end

  #Module to notify appellant if IHP Task is pending
  module IHPTaskPending
    @@template_name = self.name.split("::")[1]
    def create_ihp_tasks!
        super
        AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end
  end

  #Module to notify appellant if IHP Task is Complete
  module IHPTaskComplete
    @@template_name = self.name.split("::")[1]

    def update_status_if_children_tasks_are_closed(child_task)
      super
      if %w[RootTask DistributionTask AttorneyTask].include?(child_task.parent.type) &&
        (child_task.type.include?("InformalHearingPresentationTask") ||
        child_task.type.include?("IhpColocatedTask"))
        AppellantNotification.notify_appellant(self.appeal, @@template_name)
      end
    end
  end

  #Module to notify appellant if Privacy Act Request is Pending
  module PrivacyActPending
    @@template_name = self.name.split("::")[1]

    def create_privacy_act_task
      super
      AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end
  end

  #Module to notify appellant if Privacy Act Request is Completed
  module PrivacyActComplete
    @@template_name = self.name.split("::")[1]
    def cascade_closure_from_child_task?(child_task)
      super
      if (self.status == Constants.TASK_STATUSES.completed)
        AppellantNotification.notify_appellant(self.appeal, @@template_name)
      end
    end
  end
end