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
      # begin
        raise NoClaimantError.new(appeal_id)
      # rescue => exception
      #   # make sure to send failed status to listener
      # end
    elsif participant_id == ""
      # begin
        raise NoParticipantIdError.new(appeal_id)
      # rescue => exception
      #   # send status to listener
      # end
    end
  end

  def self.notify_appellant(appeal)
    appeal_id = appeal.id
    participant_id = appeal.participant_id
    # etc from appeal
    # get name of inner module from self.name from aaron


    AppellantNotification.handle_errors(appeal)
    msg_bdy = {
      queue_url: "caseflow_development_send_notifications",
      message_body: "Notification for #{type}",
      message_attributes: {
        "claimant" => {
          value: participant_id,
          data_type: "String"
        },
        "template_id" => {
          value: template_id,
          data_type: "String"
        },
        "appeal_id" => {
          value: appeal_id,
          data_type: "Integer"
        },
        "appeal_type" => {
          value: type,
          data_type: "String"
        },
        "status" => {
          value: "<insert status here>",
          data_type: "String"
        }
      }
    }
    Shoryuken::Client.queues("caseflow_development_send_notifications").send_message(message_body: msg_bdy)
  end

  module AppealDocketed
    template_name = self.name.split("::")[1]
    def distribution_task
      @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) ||
                             (DistributionTask.create!(appeal: @appeal, parent: @root_task) &&
                             AppellantNotification.notify_appellant(appeal))
    end

    def self.docket_appeal
      super
      AppellantNotification.notify_appellant(appeal)
    end
  end

  module AppealDecisionMailed
    template_name = self.name.split("::")[1]
    # Aspect for Legacy Appeals
    def complete_root_task!
      super
      AppellantNotification.notify_appellant(appeal)
    end

    # Aspect for AMA Appeals
    def complete_dispatch_root_task!
      super
      AppellantNotification.notify_appellant(appeal)
    end
  end

  module HearingScheduled
    template_name = self.name.split("::")[1]
    def create_hearing(task_values)
      super
      AppellantNotification.notify_appellant(appeal)
    end
  end

  module HearingPostponed
    template_name = self.name.split("::")[1]
    def postpone!
      super
      AppellantNotification.notify_appellant(appeal)
    end

    def mark_hearing_with_disposition(payload_values:, instructions: nil)
      multi_transaction do
        if payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
          update_hearing_disposition_and_notes(payload_values)
        elsif payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed
          update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
          AppellantNotification.notify_appellant(appeal)
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
    template_name = self.name.split("::")[1]
    def cancel!
      super
      AppellantNotification.notify_appellant(appeal)
    end
  end

  module IHPTaskPending
    template_name = self.name.split("::")[1]
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
        AppellantNotification.notify_appellant(appeal)
      end
    end
  end

  module IHPTaskComplete
    template_name = self.name.split("::")[1]
    def update_status_if_children_tasks_are_closed(child_task)
      if children.any? && children.open.empty? && on_hold?
        if assigned_to.is_a?(Organization) && cascade_closure_from_child_task?(child_task)
          return all_children_cancelled_or_completed
        end

        if %w[RootTask DistributionTask AttorneyTask].include?(child_task.parent.type) &&
           (child_task.type.include?("InformalHearingPresentationTask") ||
           child_task.type.include?("IhpColocatedTask"))
           AppellantNotification.notify_appellant(appeal)
        end
        update_task_if_children_tasks_are_completed
      end
    end
  end

  module PrivacyActPending
    template_name = self.name.split("::")[1]
    def self.create_privacy_act_task
      super
      AppellantNotification.notify_appellant(appeal)
    end
  end

  module PrivacyActComplete
    template_name = self.name.split("::")[1]
    def cascade_closure_from_child_task?(child_task)
      if child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
        AppellantNotification.notify_appellant(appeal)
      end
      child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
    end
  end
end

# inner modules need selfs