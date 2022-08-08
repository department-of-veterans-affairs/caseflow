# frozen_string_literal: true

# Module containing Aspect Overrides to Classes used to Track Statuses for Appellant Notification
module AppellantNotification
  class NoParticipantIdError < StandardError
    def initialize(appeal_id, message = "There is no participant ID")
      super(message + " for #{appeal_id}")
    end
  end

  class NoClaimantError < StandardError
    def initialize(appeal_id, message = "There is no claimant")
      super(message + " for #{appeal_id}")
    end
  end

  class NoAppealError < StandardError
    def initialize(appeal_id, message = "There is no appeal")
      super(message + " for #{appeal_id}")
    end
  end

  def self.handle_errors(appeal)
    if !appeal.nil?
      # just rails logger
      appeal_id = appeal.id
      claimant = appeal.claimant
      participant_id = appeal.claimant&.participant_id
      if claimant.nil?
        begin
          fail NoClaimantError, appeal_id
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          error.message
        end
      elsif participant_id == ""
        begin
          fail NoParticipantIdError, appeal_id
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          error.message
        end
      else
        "Success"
      end
    else
      # if appeal is null
      begin
        fail NoAppealError, appeal
      rescue StandardError => error
        Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
        Raven.capture_exception(error, extra: { hearing_day_id: id, message: error.message })
      end
      # rails logger and raven
    end
  end

  def self.notify_appellant(appeal, template_name, queue = Shoryuken::Client.queues(ActiveJob::Base.queue_name_prefix + "_send_notifications"))
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
        claimant: {
          value: participant_id,
          data_type: "String"
        },
        # "template_id" => {
        #   value: template_id,
        #   data_type: "String"
        # },
        template_name: {
          value: template_name,
          data_type: "String"
        },
        appeal_id: {
          value: appeal_id,
          data_type: "Integer"
        },
        appeal_type: {
          value: appeal_type, # legacy vs ama
          data_type: "String"
        },
        status: {
          value: status,
          data_type: "String"
        }
      }
    }
  end
end
