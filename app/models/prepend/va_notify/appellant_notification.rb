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
      info = {}
      info[:appeal_type] = appeal.class.to_s
      info[:appeal_id] = (info[:appeal_type] == "Appeal") ? appeal.uuid : appeal.vacols_id
      claimant = appeal.claimant
      info[:participant_id] = appeal.claimant_participant_id
      if claimant.nil?
        begin
          fail NoClaimantError, info[:appeal_id]
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          info[:status] = error.status
        end
      elsif info[:participant_id] == "" || info[:participant_id].nil?
        begin
          fail NoParticipantIdError, info[:appeal_id]
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          info[:status] = error.status
        end
      else
        info[:status] = "Success"
      end
    else
      fail NoAppealError
    end
    info
  end

  def self.notify_appellant(
    appeal,
    template_name
    # queue = Shoryuken::Client.queues(ActiveJob::Base.queue_name_prefix + "_send_notifications.fifo")
  )
    msg_bdy = create_payload(appeal, template_name)
    # queue.send_message(msg_bdy)
  end

  def self.create_payload(appeal, template_name)
    info = AppellantNotification.handle_errors(appeal)
    VANotifySendMessageTemplate.new(info, template_name)
  end
end
