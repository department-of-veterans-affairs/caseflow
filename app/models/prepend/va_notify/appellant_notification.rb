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
    appeal_type = appeal.class.to_s
    appeal_state = AppealState.find_by(appeal_id: appeal.id, appeal_type: appeal_type) ||
                   AppealState.create!(appeal_id: appeal.id, appeal_type: appeal_type)
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
        privacy_act_complete: false
      )
    when "appeal_docketed"
      appeal_state.update!(appeal_docketed: true)
    when "appeal_cancelled"
      appeal_state.update!(
        decision_mailed: false,
        appeal_docketed: false,
        hearing_postponed: false,
        hearing_withdrawn: false,
        hearing_scheduled: false,
        vso_ihp_pending: false,
        vso_ihp_complete: false,
        privacy_act_pending: false,
        privacy_act_complete: false,
        scheduled_in_error: false,
        appeal_cancelled: true
      )
    when "hearing_postponed"
      appeal_state.update!(hearing_postponed: true, hearing_scheduled: false)
    when "hearing_withdrawn"
      appeal_state.update!(hearing_withdrawn: true, hearing_postponed: false, hearing_scheduled: false)
    when "hearing_scheduled"
      appeal_state.update!(hearing_scheduled: true, hearing_postponed: false, scheduled_in_error: false)
    when "scheduled_in_error"
      appeal_state.update!(scheduled_in_error: true, hearing_scheduled: false)
    when "vso_ihp_pending"
      appeal_state.update!(vso_ihp_pending: true, vso_ihp_complete: false)
    when "vso_ihp_cancelled"
      appeal_state.update!(vso_ihp_pending: false, vso_ihp_complete: false)
    when "vso_ihp_complete"
      # Only updates appeal state if ALL ihp tasks are completed
      if appeal.tasks.open.where(type: IhpColocatedTask.name).empty? &&
         appeal.tasks.open.where(type: InformalHearingPresentationTask.name).empty?
        appeal_state.update!(vso_ihp_complete: true, vso_ihp_pending: false)
      end
    when "privacy_act_pending"
      appeal_state.update!(privacy_act_pending: true, privacy_act_complete: false)
    when "privacy_act_complete"
      # Only updates appeal state if ALL privacy act tasks are completed
      open_tasks = appeal.tasks.open
      if open_tasks.where(type: FoiaColocatedTask.name).empty? && open_tasks.where(type: PrivacyActTask.name).empty? &&
         open_tasks.where(type: HearingAdminActionFoiaPrivacyRequestTask.name).empty? &&
         open_tasks.where(type: FoiaRequestMailTask.name).empty? && open_tasks.where(type: PrivacyActRequestMailTask.name).empty?
        appeal_state.update!(privacy_act_complete: true, privacy_act_pending: false)
      end
    when "privacy_act_cancelled"
      # Only updates appeal state if ALL privacy act tasks are completed
      open_tasks = appeal.tasks.open
      if open_tasks.where(type: FoiaColocatedTask.name).empty? && open_tasks.where(type: PrivacyActTask.name).empty? &&
         open_tasks.where(type: HearingAdminActionFoiaPrivacyRequestTask.name).empty? &&
         open_tasks.where(type: FoiaRequestMailTask.name).empty? && open_tasks.where(type: PrivacyActRequestMailTask.name).empty?
        appeal_state.update!(privacy_act_pending: false)
      end
    end
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

  def self.create_payload(appeal, template_name, appeal_status = nil)
    message_attributes = AppellantNotification.handle_errors(appeal)
    VANotifySendMessageTemplate.new(message_attributes, template_name, appeal_status)
  end
end
