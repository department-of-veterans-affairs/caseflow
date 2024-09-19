# frozen_string_literal: true

# Module containing Aspect Overrides to Classes used to Track Statuses for Appellant Notification
module AppellantNotification
  extend ActiveSupport::Concern
  class NoParticipantIdError < StandardError
    def initialize(appeal_id, message = "There is no participant_id")
      super(message + " for appeal with id #{appeal_id}")
    end

    def status
      "No participant_id"
    end
  end

  class NoClaimantError < StandardError
    def initialize(appeal_id, message = "There is no claimant")
      super(message + " for appeal with id #{appeal_id}")
    end

    def status
      "No claimant"
    end
  end

  class InactiveAppealError < StandardError
    def initialize(appeal_id, message = "The appeal status is inactive")
      super(message + " for appeal with id #{appeal_id}")
    end

    def status
      "Inactive"
    end
  end

  class NoAppealError < StandardError; end

  def self.handle_errors(appeal, template_name)
    fail NoAppealError if appeal.nil?
    if template_name == Constants.EVENT_TYPE_FILTERS.quarterly_notification && !appeal.active?
      fail InactiveAppealError, appeal.external_id
    end

    message_attributes = {}
    message_attributes[:appeal_type] = appeal.class.to_s
    message_attributes[:appeal_id] = appeal.external_id
    message_attributes[:participant_id] = appeal.claimant_participant_id
    claimant = get_claimant(appeal)

    AppellantNotification.error_handling_messages_and_attributes(appeal, claimant, message_attributes)
  end

  # Purpose: Method to check appeal state for statuses and send out a notification based on
  # which statuses are turned on in the appeal state
  #
  # Params: appeal object (AMA of Legacy)
  #         temaplate_name (ex. quarterly_notification, appeal_docketed, etc.)
  #         appeal_status (only used for quarterly notifications)
  #
  # Response: Create notification and return it to SendNotificationJob

  def self.notify_appellant(
    appeal,
    template_name,
    appeal_status = nil
  )
    msg_bdy = create_payload(appeal, template_name, appeal_status)

    if template_name == "Appeal docketed" && msg_bdy.appeal_type == "LegacyAppeal"
      Notification.create!(
        appeals_id: msg_bdy.appeal_id,
        appeals_type: msg_bdy.appeal_type,
        event_type: template_name,
        notification_type: "Email and SMS",
        participant_id: msg_bdy.participant_id,
        event_date: Time.zone.today,
        notifiable: appeal
      )
    end
    SendNotificationJob.perform_later(msg_bdy.to_json)
  end

  def self.create_payload(appeal, template_name, appeal_status = nil)
    message_attributes = AppellantNotification.handle_errors(appeal, template_name)
    VANotifySendMessageTemplate.new(message_attributes, template_name, appeal_status)
  end

  def self.get_claimant(appeal)
    if appeal.is_a?(Appeal)
      appeal.claimant
    elsif appeal.is_a?(LegacyAppeal)
      appeal.appellant_is_not_veteran ? appeal.person_for_appellant : appeal.veteran
    end
  end

  def self.error_handling_messages_and_attributes(appeal, claimant, message_attributes)
    begin
      if claimant.nil?
        fail NoClaimantError, message_attributes[:appeal_id]
      elsif message_attributes[:participant_id].blank?
        fail NoParticipantIdError, message_attributes[:appeal_id]
      elsif appeal.veteran_appellant_deceased?
        message_attributes[:status] = "Failure Due to Deceased"
      else
        message_attributes[:status] = "Success"
      end
    rescue StandardError => error
      Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
      message_attributes[:status] = error.status
    end
    message_attributes
  end
end
