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

  # Updates appeal_state database when notification event is triggered
  # to keep track of the state of each appeal
  def self.appeal_mapper(appeal_id, appeal_type, event)
    current_user = RequestStore[:current_user] || User.system_user
    appeal_state = AppealState.find_by(appeal_id: appeal_id, appeal_type: appeal_type) ||
                   AppealState.create!(appeal_id: appeal_id, appeal_type: appeal_type, created_by_id: current_user.id)
    case event
    when "decision_mailed"
      appeal_state.update!(
        decision_mailed: true,
        appeal_docketed: false,
        hearing_postponed: false,
        hearing_withdrawn: false,
        hearing_scheduled: false,
        vso_ihp_pending: false,
        vso_ihp_complete: false,
        privacy_act_pending: false,
        privacy_act_complete: false,
        updated_by_id: current_user.id
      )
    when "appeal_docketed"
      appeal_state.update!(appeal_docketed: true, updated_by_id: current_user.id)
    when "hearing_postponed"
      appeal_state.update!(hearing_postponed: true, hearing_scheduled: false, updated_by_id: current_user.id)
    when "hearing_withdrawn"
      appeal_state.update!(hearing_withdrawn: true, hearing_postponed: false, hearing_scheduled: false, updated_by_id: current_user.id)
    when "hearing_scheduled"
      appeal_state.update!(hearing_scheduled: true, hearing_postponed: false, updated_by_id: current_user.id)
    when "vso_ihp_pending"
      appeal_state.update!(vso_ihp_pending: true, vso_ihp_complete: false, updated_by_id: current_user.id)
    when "vso_ihp_complete"
      if !appeal.tasks.open.where(type.include?("Ihp")) &&
         !appeal.tasks.open.where(type.include?("InformalHearingPresentationTask"))
        appeal_state.update!(vso_ihp_complete: true, vso_ihp_pending: false, updated_by_id: current_user.id)
      end
    when "privacy_act_pending"
      appeal_state.update!(privacy_act_pending: true, privacy_act_complete: false, updated_by_id: current_user.id)
    when "privacy_act_complete"
      if !appeal.tasks.open.where(type.include?("Foia")) && !appeal.tasks.open.where(type.include?("PrivacyAct"))
        appeal_state.update!(privacy_act_complete: true, privacy_act_pending: false, updated_by_id: current_user.id)
      end
    end
  end

  def self.notify_appellant(
    appeal,
    template_name
  )
    msg_bdy = create_payload(appeal, template_name)
    notification_type =
      if FeatureToggle.enabled?(:va_notify_email) && FeatureToggle.enabled?(:va_notify_sms)
        "Email and SMS"
      elsif FeatureToggle.enabled?(:va_notify_email)
        "Email"
      elsif FeatureToggle.enabled?(:va_notify_sms)
        "SMS"
      else
        "None"
      end
    # rubocop:disable Layout/LineLength
    if template_name == "Appeal docketed" && FeatureToggle.enabled?(:appeal_docketed_event) && msg_bdy.appeal_type == "LegacyAppeal"
      Notification.create!(
        appeals_id: msg_bdy.appeal_id,
        appeals_type: msg_bdy.appeal_type,
        event_type: template_name,
        notification_type: notification_type,
        participant_id: msg_bdy.participant_id,
        event_date: Time.zone.today
      )
      SendNotificationJob.perform_later(msg_bdy.to_json)
    elsif template_name == "Appeal docketed" && !FeatureToggle.enabled?(:appeal_docketed_event) && msg_bdy.appeal_type == "LegacyAppeal"
      nil
    else SendNotificationJob.perform_later(msg_bdy.to_json)
    end
    # rubocop:enable Layout/LineLength
  end

  def self.create_payload(appeal, template_name)
    message_attributes = AppellantNotification.handle_errors(appeal)
    VANotifySendMessageTemplate.new(message_attributes, template_name)
  end
end
