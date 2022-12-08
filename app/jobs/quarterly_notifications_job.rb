# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule

  # Purpose: Loop through all open appeals quarterly and sends statuses for VA Notify
  #
  # Params: none
  #
  # Response: None
  def perform
    appeal_states = AppealState.where.not(decision_mailed: true, appeal_cancelled: true)
    appeal_states.each do |state|
      if state.appeal_type == "Appeal"
        appeal = Appeal.find_by(id: state.appeal_id)
      elsif state.appeal_type == "LegacyAppeal"
        appeal = LegacyAppeal.find_by(id: state.appeal_id)
      end
      if appeal.nil?
        fail Caseflow::Error::AppealNotFound, "Standard Error ID: " + SecureRandom.uuid + " The appeal was unable to be found."
      else
        send_quarterly_notifications(state, appeal)
      end
    end
  end

  private

  # Purpose: Method to be called with an error need to be logged to the rails logger
  #
  # Params: error_message (Expecting a string) - Message to be logged to the logger
  #
  # Response: None
  def log_error(error_message)
    Rails.logger.error(error_message)
  end

  # Purpose: Method to check appeal state for statuses and send out a notification based on
  # which statuses are turned on in the appeal state
  #
  # Params: appeal state, appeal
  #
  # Response: SendNotificationJob queued to send_notification SQS queue
  def send_quarterly_notifications(appeal_state, appeal)
    # if either there's a hearing postponed or a hearing scheduled in error
    if appeal_state.hearing_postponed || appeal_state.scheduled_in_error
      # appeal status is Hearing to be Rescheduled / Privacy Act Pending
      if appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      # appeal status is Hearing to be Rescheduled
      else
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      end
    # if there's a hearing scheduled
    elsif appeal_state.hearing_scheduled
      # if there's privacy act tasks pending
      # appeal status is Hearing Scheduled /  Privacy Act Pending
      if appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      # if there's no privacy act tasks pending
      # appeal status is Hearing Scheduled
      elsif !appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      end
    # if there's no hearing scheduled and no hearing withdrawn
    elsif !appeal_state.hearing_withdrawn
      # if there's ihp tasks pending and privacy act tasks pending
      # appeal status is VSO IHP Pending / Privacy Act Pending
      if appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      # if there's no ihp tasks pending and there are privacy act tasks pending
      # appeal status is Privacy Act Pending
      elsif !appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      # if there's no privacy acts pending and there are ihp tasks pending
      # appeal status is VSO IHP Pending
      elsif appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      # if there's no privacy acts pending or ihp tasks pending
      # appeal status is Appeal Docketed
      elsif !appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
      end
    # appeal status is Appeal Docketed
    else
      AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
    end
  end
end
