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

  class NoAppealError < StandardError; end

  def self.handle_errors(appeal)
    fail NoAppealError if appeal.nil?

    message_attributes = {}
    message_attributes[:appeal_type] = appeal.class.to_s
    message_attributes[:appeal_id] = (appeal.class.to_s == "Appeal") ? appeal.uuid : appeal.vacols_id
    message_attributes[:participant_id] = appeal.claimant_participant_id
    claimant = get_claimant(appeal)

    AppellantNotification.error_handling_messages_and_attributes(appeal, claimant, message_attributes)
  end
  # Public: Updates/creates appeal state based on event type
  #
  # appeal - appeal that was found in appeal_mapper
  # event - The module that is being triggered to send a notification
  #
  # Examples
  #
  #  AppellantNotification.update_appeal_state(appeal, "hearing_postponed")
  #   # => A new appeal state is created if it doesn't exist
  #   or the existing appeal state is updated, then appeal_state.hearing_postponed becomes true

  def self.update_appeal_state(appeal, event)
    appeal.appeal_state.process_event_to_update_appeal_state!(event)
  end
  # Public: Finds the appeal based on the id and type, then calls update_appeal_state to create/update appeal state
  #
  # appeal_id  - id of appeal
  # appeal_type - string of appeal object's class (e.g. "LegacyAppeal")
  # event - The module that is being triggered to send a notification
  #
  # Examples
  #
  #  AppellantNotification.appeal_mapper(1, "Appeal", "hearing_postponed")
  #   # => A new appeal state is created if it doesn't exist
  #   or the existing appeal state is updated, then appeal_state.hearing_postponed becomes true

  def self.appeal_mapper(appeal_id, appeal_type, event)
    if appeal_type == "Appeal"
      appeal = Appeal.find_by(id: appeal_id)
      AppellantNotification.update_appeal_state(appeal, event)
    elsif appeal_type == "LegacyAppeal"
      appeal = LegacyAppeal.find_by(id: appeal_id)
      AppellantNotification.update_appeal_state(appeal, event)
    else
      Rails.logger.error("Appeal type not supported for " + event)
    end
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

    return nil if template_name == "Appeal docketed" &&
                  msg_bdy.appeal_type == "LegacyAppeal"

    if template_name == "Appeal docketed" && msg_bdy.appeal_type == "LegacyAppeal"
      Notification.create!(
        appeals_id: msg_bdy.appeal_id,
        appeals_type: msg_bdy.appeal_type,
        event_type: template_name,
        notification_type: notification_type,
        participant_id: msg_bdy.participant_id,
        event_date: Time.zone.today,
        notifiable: appeal
      )
    end
    SendNotificationJob.perform_later(msg_bdy.to_json)
  end

  def self.create_payload(appeal, template_name, appeal_status = nil)
    message_attributes = AppellantNotification.handle_errors(appeal)
    VANotifySendMessageTemplate.new(message_attributes, template_name, appeal_status)
  end

  # def self.notification_type
  #   notification_type =
  #     if FeatureToggle.enabled?(:va_notify_email) && FeatureToggle.enabled?(:va_notify_sms)
  #       "Email and SMS"
  #     elsif FeatureToggle.enabled?(:va_notify_email)
  #       "Email"
  #     elsif FeatureToggle.enabled?(:va_notify_sms)
  #       "SMS"
  #     else
  #       "None"
  #     end
  #   notification_type
  # end

  def self.get_claimant(appeal)
    appeal_type = appeal.class.to_s
    participant_id = appeal.claimant_participant_id
    claimant =
      if appeal_type == "Appeal"
        appeal.claimant
      elsif appeal_type == "LegacyAppeal"
        veteran = Veteran.find_by(participant_id: participant_id)
        person = Person.find_by(participant_id: participant_id)
        appeal.appellant_is_not_veteran ? person : veteran
      end
    claimant
  end

  def self.error_handling_messages_and_attributes(appeal, claimant, message_attributes)
    begin
      if claimant.nil?
        fail NoClaimantError, message_attributes[:appeal_id]
      elsif message_attributes[:participant_id] == "" || message_attributes[:participant_id].nil?
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
