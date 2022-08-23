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
      appeal_id = appeal.id
      claimant = appeal.claimant
      participant_id = appeal.claimant_participant_id || AppellantNotification.legacy_non_vet_claimant_id(appeal)
      if claimant.nil?
        begin
          fail NoClaimantError, appeal_id
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          error.status
        end
      elsif participant_id == "" || participant_id.nil?
        begin
          fail NoParticipantIdError, appeal_id
        rescue StandardError => error
          Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
          error.status
        end
      else
        "Success"
      end
    else
      fail NoAppealError
    end
  end

  def self.legacy_non_vet_claimant_id(appeal)
    # find non veteran claimant participant id for legacy appeals
    BgsPowerOfAttorney.fetch_bgs_poa_by_participant_id(appeal.veteran.participant_id)[:claimant_participant_id]
  end

  def self.notify_appellant(
    appeal,
    template_name,
    queue = Shoryuken::Client.queues(ActiveJob::Base.queue_name_prefix + "_send_notifications.fifo")
  )
    msg_bdy = create_payload(appeal, template_name)
    queue.send_message(msg_bdy)
  end

  def self.create_payload(appeal, template_name)
    status = AppellantNotification.handle_errors(appeal)
    appeal_id = appeal.id
    participant_id = appeal.claimant_participant_id
    appeal_type = appeal.class.to_s

    {
      queue_url: "caseflow_development_send_notifications",
      message_body: "Notification for #{appeal_type}, #{template_name}",
      message_attributes: {
        "participant_id": {
          string_value: participant_id,
          data_type: "String"
        },
        "template_name": {
          string_value: template_name,
          data_type: "String"
        },
        "appeal_id": {
          string_value: appeal_id,
          data_type: "String"
        },
        "appeal_type": {
          string_value: appeal_type, # legacy vs ama
          data_type: "String"
        },
        "status": {
          string_value: status,
          data_type: "String"
        }
      }
    }
  end
end
