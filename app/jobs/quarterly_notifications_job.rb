# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  queue_as ApplicationController.dependencies_faked? ? :send_notifications : :"send_notifications.fifo"

  # Purpose: Loop through all open appeals quarterly and sends statuses for VA Notify
  #
  # Params: none
  #
  # Response: None
  def perform
    notifications = Notification.all
    notifications.each do |notif|
      appeal = notif.appeal
      if appeal.active?
        appeal_state = AppealState.find(appeal: appeal)
        hearing_rescheduled(appeal_state, appeal)
        appeal_docketed(appeal_state, appeal)
        hearing_scheduled(appeal_state, appeal)
        privacy_act_pending(appeal_state, appeal)
        vso_ihp_pending(appeal_state, appeal)
        hearing_scheduled_privacy_pending(appeal_state, appeal)
        hearing_rescheduled_privacy_pending(appeal_state, appeal)
        vso_ihp_privacy_pending(appeal_state, appeal)
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

  # FIXME might need to add checks for tasks for rescheduled hearings since
  # the appeal state looks the same as first time scheduled hearings
  def hearing_rescheduled(appeal_state, appeal)
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    elsif !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    elsif !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    elsif !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    elsif appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          !appeal_state.hearing_postponed && !appeal_state.hearing_withdrawn
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    end
  end
  # FIXME need to check tasks to find difference between scheduled hearing & rescheduled hearing
  def appeal_docketed(appeal_state, appeal)
    if !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
       !appeal_state.hearing_postponed && !appeal_state.hearing_withdrawn
      AppellantNotification.notify_appellant(appeal, "Appeal Docketed")
    elsif appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          !appeal_state.hearing_postponed && !appeal_state.hearing_withdrawn
      AppellantNotification.notify_appellant(appeal, "Appeal Docketed")
    end
  end

  # FIXME need to check tasks to find difference between scheduled hearing & rescheduled hearing
  def hearing_scheduled(appeal_state, appeal)
    if appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled")
    elsif appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled")
    end
  end

  def privacy_act_pending(appeal_state, appeal)
    if !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Privacy Act Pending")
    end
  end

  def vso_ihp_pending(appeal_state, appeal)
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "VSO IHP Pending")
    end
  end

  def hearing_scheduled_privacy_pending(appeal_state, appeal)
    if appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled /  Privacy Act Pending")
    elsif appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled /  Privacy Act Pending")
    end
  end

  def vso_ihp_privacy_pending(appeal_state, appeal)
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "VSO IHP Pending / Privacy Act Pending")
    elsif appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled /  Privacy Act Pending")
    end
  end

  def hearing_rescheduled_privacy_pending(appeal_state, appeal)
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    elsif !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    elsif !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    elsif !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    end
  end
end
