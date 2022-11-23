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

  def hearing_rescheduled(appeal_state, appeal)
    # when there is a vso ihp pending and a scheduled in error NOT rescheduled
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    # when there are no pending tasks and a scheduled in error NOT rescheduled
    elsif !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    # when there is a vso ihp pending and a hearing postponed NOT rescheduled
    elsif !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    # when there are no pending tasks and a hearing postponed NOT rescheduled
    elsif !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    # when there are no pending tasks and a scheduled in error RESCHEDULED IMMEDIATELY
    elsif appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          !appeal_state.hearing_postponed && !appeal_state.hearing_withdrawn &&
          !appeal.tasks.open.where(type: "AssignHearingDispositionTask") &&
          appeal.tasks.open.where(type: "AssignHearingDispositionTask", status: "cancelled")
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled")
    end
  end

  def appeal_docketed(appeal_state, appeal)
    # if there's no pending tasks, no hearing scheduled, no postponed, no withdrawn, no scheduled in error
    if !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
       !appeal_state.hearing_postponed && !appeal_state.hearing_withdrawn
      AppellantNotification.notify_appellant(appeal, "Appeal Docketed")
    # if there's no pending tasks, no hearing scheduled, no postponed, but there is a hearing withdrawn
    elsif !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && !appeal_state.scheduled_in_error &&
          !appeal_state.hearing_postponed && appeal_state.hearing_withdrawn
      AppellantNotification.notify_appellant(appeal, "Appeal Docketed")
    # if there's nothing else except a hearing scheduled in error, rescheduled, then withdrawn
    elsif appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          !appeal_state.privacy_act_pending && appeal_state.scheduled_in_error &&
          !appeal_state.hearing_postponed && appeal_state.hearing_withdrawn
      AppellantNotification.notify_appellant(appeal, "Appeal Docketed")
    end
  end

  def hearing_scheduled(appeal_state, appeal)
    # if there's a pending ihp & privacy act task and there's a scheduled hearing
    if appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled")
    # if there's no pending tasks and there's a scheduled hearing
    elsif appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled")
    end
  end

  def privacy_act_pending(appeal_state, appeal)
    # if there's no scheduled hearing or ihp task, but there is privacy act tasks
    if !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Privacy Act Pending")
    end
  end

  def vso_ihp_pending(appeal_state, appeal)
    # if there's no hearing scheduled or privacy act task, but there is ihp task
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       !appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "VSO IHP Pending")
    end
  end

  def hearing_scheduled_privacy_pending(appeal_state, appeal)
    # if there's a scheduled hearing, ihp tasks, and privacy act tasks
    if appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled /  Privacy Act Pending")
    # if there's a hearing scheduled and privacy act task, but no ihp task
    elsif appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "Hearing Scheduled /  Privacy Act Pending")
    end
  end

  def vso_ihp_privacy_pending(appeal_state, appeal)
    # if there's privacy act task and ihp task, but no hearing scheduled
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending
      AppellantNotification.notify_appellant(appeal, "VSO IHP Pending / Privacy Act Pending")
    end
  end

  def hearing_rescheduled_privacy_pending(appeal_state, appeal)
    # if there's ihp task, privacy act task, and a hearing scheduled in error but NOT rescheduled
    if !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
       appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    # if there's privacy act task and a hearing scheduled in error but NOT rescheduled
    elsif !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending && appeal_state.scheduled_in_error
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    # if there's ihp task, privacy act task, and hearing postponed but NOT rescheduled
    elsif !appeal_state.hearing_scheduled && appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending && appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    # if there's privacy act task and hearing postponed but NOT rescheduled
    elsif !appeal_state.hearing_scheduled && !appeal_state.vso_ihp_pending &&
          appeal_state.privacy_act_pending && appeal_state.hearing_postponed
      AppellantNotification.notify_appellant(appeal, "Hearing to be Rescheduled / Privacy Act Pending")
    end
  end
end
