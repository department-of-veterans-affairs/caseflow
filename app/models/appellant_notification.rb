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

  def self.handle_errors(appeal)
    appeal_id = appeal.id
    claimant = appeal.claimant
    participant_id = appeal.claimant&.participant_id
    if claimant == nil
      begin
        raise NoClaimantError.new(appeal_id)
      rescue => exception
        exception.message
      end
    elsif participant_id == ""
      begin
        raise NoParticipantIdError.new(appeal_id)
      rescue => exception
        exception.message
      end
    else
      "Success"
    end
  end

  def self.notify_appellant(appeal, template_name)
    msg_bdy = create_payload(appeal, template_name)
    Shoryuken::Client.queues(ActiveJob::Base.queue_name_prefix + '_send_notifications').send_message(msg_bdy)
  end

  def self.create_payload(appeal, template_name)
    appeal_id = appeal.id
    participant_id = appeal.claimant.participant_id
    appeal_type = appeal.class.to_s

    status = AppellantNotification.handle_errors(appeal)

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

  module AppealDocketed
    @@template_name = self.name.split("::")[1]
    
    def create_tasks_on_intake_success!
      if vha_has_issues? && FeatureToggle.enabled?(:vha_predocket_appeals, user: RequestStore.store[:current_user])
        PreDocketTasksFactory.new(self).call_vha
      elsif edu_predocket_needed?
        PreDocketTasksFactory.new(self).call_edu
      else
        InitialTasksFactory.new(self).create_root_and_sub_tasks! && AppellantNotification.notify_appellant(self, @@template_name)
      end
      create_business_line_tasks!
    end

    def docket_appeal
      super
      AppellantNotification.notify_appellant(self.appeal, @@template_name)
    end
  end

  module AppealDecisionMailed
    @@template_name = self.name.split("::")[1]
    # Aspect for Legacy Appeals
    def complete_root_task!
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end

    # Aspect for AMA Appeals
    def complete_dispatch_root_task!
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end

  module HearingScheduled
    @@template_name = self.name.split("::")[1]
    def create_hearing(task_values)
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end

  module HearingPostponed
    @@template_name = self.name.split("::")[1]
    def postpone!
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end

    def mark_hearing_with_disposition(payload_values:, instructions: nil)
      multi_transaction do
        if payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
          update_hearing_disposition_and_notes(payload_values)
        elsif payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed
          update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
          AppellantNotification.notify_appellant(appeal, @@template_name)
        end
        clean_up_virtual_hearing
        reschedule_or_schedule_later(
          instructions: instructions,
          after_disposition_update: payload_values[:after_disposition_update]
        )
      end
    end
  end

  module HearingWithdrawn
    @@template_name = self.name.split("::")[1]
    def cancel!
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end

  module IHPTaskPending
    @@template_name = self.name.split("::")[1]
    def create_ihp_tasks!
      appeal = @parent.appeal
      appeal.representatives.select { |org| org.should_write_ihp?(appeal) }.map do |vso_organization|
        # For some RAMP appeals, this method may run twice.
        existing_task = InformalHearingPresentationTask.find_by(
          appeal: appeal,
          assigned_to: vso_organization
        )
        existing_task || InformalHearingPresentationTask.create!(
          appeal: appeal,
          parent: @parent,
          assigned_to: vso_organization
        )
        AppellantNotification.notify_appellant(appeal, @@template_name)
      end
    end
  end

  module IHPTaskComplete
    @@template_name = self.name.split("::")[1]

    def update_status_if_children_tasks_are_closed(child_task)
      if children.any? && children.open.empty? && on_hold?
        if assigned_to.is_a?(Organization) && cascade_closure_from_child_task?(child_task)
          return all_children_cancelled_or_completed
        end

        if %w[RootTask DistributionTask AttorneyTask].include?(child_task.parent.type) &&
           (child_task.type.include?("InformalHearingPresentationTask") ||
           child_task.type.include?("IhpColocatedTask"))
           AppellantNotification.notify_appellant(appeal, @@template_name)
        end
        update_task_if_children_tasks_are_completed
      end
    end
  end

  module PrivacyActPending
    @@template_name = self.name.split("::")[1]

    def create_privacy_act_task
      super
      AppellantNotification.notify_appellant(appeal, @@template_name)
    end
  end

  module PrivacyActComplete
    @@template_name = self.name.split("::")[1]

    def self.cascade_closure_from_child_task?(child_task)
      if child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
        AppellantNotification.notify_appellant(self.appeal, @@template_name)
      end
      child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
    end
  end
end