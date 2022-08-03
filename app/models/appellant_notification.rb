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

  def self.handle_errors(participant_id, appeal_id)
    # claimant = appeal_id.claimant # get claimant from appeal_id
    claimant = nil # fake that a claimant shows up, can use nil to throw a NoClaimantError or string to make it pass
    if claimant == nil
      raise NoClaimantError.new(appeal_id)
    elsif participant_id == nil
      raise NoParticipantIdError.new(appeal_id)
    end
  end
  
  ## Testing just to make sure error throws
  # raise NoParticipantIdError.new('123456')

  # begin
  #   raise NoParticipantIdError.new("123456")
  # rescue => e
  #   puts "writes to DB about failure"
  #   could be a way to stop from crashing
  # end

  def self.notify_appellant(appeal_id, participant_id, type, template_id = 0)
    AppellantNotification.handle_errors(participant_id, appeal_id)
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
    def distribution_task
      @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) ||
                             (DistributionTask.create!(appeal: @appeal, parent: @root_task) &&
                             AppellantNotification.notify_appellant(@appeal.id, @appeal.claimant_participant_id, @appeal.class.to_s, 1111))
    end

    def docket_appeal
      super
      AppellantNotification.notify_appellant(appeal.id, appeal.claimant_participant_id, appeal.class.to_s, 1111)
    end
  end

  module AppealDecisionMailed
    # Aspect for Legacy Appeals
    def complete_root_task!
      super
      AppellantNotification.notify_appellant(@appeal.id, @appeal.claimant_participant_id, @appeal.class.to_s, 1112)
    end

    # Aspect for AMA Appeals
    def complete_dispatch_root_task!
      super
      AppellantNotification.notify_appellant(appeal.id, appeal.claimant_participant_id, appeal.class.to_s, 1112)
    end
  end

  module HearingScheduled
    def create_hearing(task_values)
      super
      AppellantNotification.notify_appellant(appeal.id, appeal.claimant_participant_id, appeal.class.to_s, 1113)
    end
  end

  module HearingPostponed
    def postpone!
      super
      AppellantNotification.notify_appellant(appeal.id, appeal.claimant_participant_id, appeal.class.to_s, 1114)
    end

    def mark_hearing_with_disposition(payload_values:, instructions: nil)
      multi_transaction do
        if payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
          update_hearing_disposition_and_notes(payload_values)
        elsif payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed
          update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
          AppellantNotification.notify_appellant(appeal.id, appeal.claimant_participant_id, appeal.class.to_s, 1114)
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
    def cancel!
      super
      AppellantNotification.notify_appellant(appeal.id, appeal.claimant_participant_id, appeal.class.to_s, 1115)
    end
  end

  module IHPTaskPending
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
        AppellantNotification.notify_appellant(appeal.id, appeal.claimant_participant_id, appeal.class.to_s, 1116)
      end
    end
  end

  module IHPTaskComplete
    def update_status_if_children_tasks_are_closed(child_task)
      if children.any? && children.open.empty? && on_hold?
        if assigned_to.is_a?(Organization) && cascade_closure_from_child_task?(child_task)
          return all_children_cancelled_or_completed
        end

        if %w[RootTask DistributionTask AttorneyTask].include?(child_task.parent.type) &&
           (child_task.type.include?("InformalHearingPresentationTask") ||
           child_task.type.include?("IhpColocatedTask"))
           AppellantNotification.notify_appellant(child_task.appeal.id, child_task.appeal.claimant_participant_id, child_task.appeal.class.to_s, 1117)
        end
        update_task_if_children_tasks_are_completed
      end
    end
  end

  module PrivacyActPending
    def self.create_privacy_act_task
      super
      # AppellantNotification.notify_appellant(appeal_id, participant_id, type, template_id)
      AppellantNotification.notify_appellant('bib', '2', '3', '4')
    end
  end

  module PrivacyActComplete
    def cascade_closure_from_child_task?(child_task)
      if child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
        AppellantNotification.notify_appellant(child_task.appeal.id, child_task.appeal.claimant_participant_id, child_task.appeal.class.to_s, 1119)
      end
      child_task.is_a?(FoiaTask) || child_task.is_a?(PrivacyActTask)
    end
  end
end

# Crude testing of throwing errors, run 'rails runner /app/models/appellant_notification.rb' in console
# AppellantNotification.notify_appellant('bib','2','3','4')

AppellantNotification::PrivacyActPending.create_privacy_act_task
# this works when running above command when super is commented out and artificial data is used
# maybe inner modules need selfs?