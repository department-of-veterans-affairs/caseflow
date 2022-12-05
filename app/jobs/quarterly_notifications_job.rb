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
        appeal = Appeal.find(state.appeal_id)
      elsif state.appeal_type == "LegacyAppeal"
        appeal = LegacyAppeal.find(state.appeal_id)
      end
      send_quarterly_notifications(state, appeal)
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
        AppellantNotification.notify_appellant(appeal, "Postponement of hearing")
      # appeal status is Hearing to be Rescheduled
      else
        AppellantNotification.notify_appellant(appeal, "Withdrawal of hearing")
      end
    # if there's ihp tasks pending, privacy act tasks pending, and at least one hearing scheduled
    # appeal status is Hearing Scheduled /  Privacy Act Pending
    elsif appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending && appeal_state.hearing_scheduled
      AppellantNotification.notify_appellant(appeal, "VSO IHP complete")
    # if there's ihp tasks pending and privacy act tasks pending, but no hearings scheduled
    # appeal status is VSO IHP Pending / Privacy Act Pending
    elsif appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending && !appeal_state.hearing_scheduled
      AppellantNotification.notify_appellant(appeal, "Appeal decision mailed")
    # if there's ihp tasks pending and hearings scheduled, but no privacy act tasks pending
    # appeal status is Hearing Scheduled
    elsif appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending && appeal_state.hearing_scheduled
      AppellantNotification.notify_appellant(appeal, "Hearing scheduled")
    # if there's no ihp tasks pending, and there is a hearing scheduled and privacy act tasks pending
    # appeal status is Hearing Scheduled / Privacy Act Pending
    elsif !appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending && appeal_state.hearing_scheduled
      AppellantNotification.notify_appellant(appeal, "Scheduled in error")
    # if there's no ihp tasks pending or hearing scheduled, and there are privacy act tasks pending
    # appeal status is Privacy Act Pending
    elsif !appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending && !appeal_state.hearing_scheduled
      AppellantNotification.notify_appellant(appeal, "Privacy Act request pending")
    # if there's no privacy acts pending or hearing scheduled, and there are ihp tasks pending
    # appeal status is VSO IHP Pending
    elsif appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending && !appeal_state.hearing_scheduled
      AppellantNotification.notify_appellant(appeal, "Privacy Act request complete")
    # if there's no privacy acts pending or ihp tasks pending, and there is a hearing scheduled
    # appeal status is Hearing Scheduled
    elsif !appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending && appeal_state.hearing_scheduled
      AppellantNotification.notify_appellant(appeal, "Quarterly Notification")
    # appeal status is Appeal Docketed
    else
      AppellantNotification.notify_appellant(appeal, "Appeal docketed")
    end
  end
end
