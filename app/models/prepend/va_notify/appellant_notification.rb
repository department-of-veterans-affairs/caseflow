# frozen_string_literal: true

# Module containing Aspect Overrides to Classes used to Track Statuses for Appellant Notification
module AppellantNotification
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
    if !appeal.nil?
      message_attributes = {}
      message_attributes[:appeal_type] = appeal.class.to_s
      message_attributes[:appeal_id] = (message_attributes[:appeal_type] == "Appeal") ? appeal.uuid : appeal.vacols_id
      message_attributes[:participant_id] = appeal.claimant_participant_id
      claimant =
        if message_attributes[:appeal_type] == "Appeal"
          appeal.claimant
        elsif message_attributes[:appeal_type] == "LegacyAppeal"
          veteran = Veteran.find_by(participant_id: message_attributes[:participant_id])
          person = Person.find_by(participant_id: message_attributes[:participant_id])
          appeal.appellant_is_not_veteran ? person : veteran
        end
      if claimant.nil?
        begin
          fail NoClaimantError, message_attributes[:appeal_id]
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          message_attributes[:status] = error.status
        end
      elsif message_attributes[:participant_id] == "" || message_attributes[:participant_id].nil?
        begin
          fail NoParticipantIdError, message_attributes[:appeal_id]
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          message_attributes[:status] = error.status
        end
      else
        message_attributes[:status] = "Success"
      end
    else
      fail NoAppealError
    end
    message_attributes
  end

  def self.notify_appellant(
    appeal,
    template_name
  )
    msg_bdy = create_payload(appeal, template_name)
    SendNotificationJob.perform_later(msg_bdy.to_json)
  end

  def self.create_payload(appeal, template_name)
    message_attributes = AppellantNotification.handle_errors(appeal)
    VANotifySendMessageTemplate.new(message_attributes, template_name)
  end
end
