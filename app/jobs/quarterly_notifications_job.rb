# frozen_string_literal: true

class QuarterlyNotificationsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :hearing_schedule
  QUERY_LIMIT = ENV["QUARTERLY_NOTIFICATIONS_JOB_BATCH_SIZE"]

  # Purpose: Loop through all open appeals quarterly and sends statuses for VA Notify
  #
  # Params: none
  #
  # Response: None
  def perform
    RequestStore.store[:current_user] = User.system_user
    AppealState.where.not(
      decision_mailed: true, appeal_cancelled: true
    ).find_in_batches(batch_size: QUERY_LIMIT.to_i) do |batched_appeal_states|
      batched_appeal_states.each do |appeal_state|
        # add_record_to_appeal_states_table(appeal_state.appeal)
        if appeal_state.appeal_type == "Appeal"
          appeal = Appeal.find_by(id: appeal_state.appeal_id)
        elsif appeal_state.appeal_type == "LegacyAppeal"
          appeal = LegacyAppeal.find_by(id: appeal_state.appeal_id)
        end
        if appeal.nil?
          begin
            fail Caseflow::Error::AppealNotFound, "Standard Error ID: " + SecureRandom.uuid + " The appeal was unable "\
            "to be found."
          rescue Caseflow::Error::AppealNotFound => error
            Rails.logger.error("QuarterlyNotificationsJob::Error - Unable to send a notification for "\
              "#{appeal_state&.appeal_type} ID #{appeal_state&.appeal_id} because of #{error}")
          end
        else
          begin
            MetricsService.record("Creating Quarterly Notification for #{appeal.class} ID #{appeal.id}",
                                  name: "send_quarterly_notifications(appeal_state, appeal)") do
              send_quarterly_notifications(appeal_state, appeal)
            end
          rescue StandardError => error
            Rails.logger.error("QuarterlyNotificationsJob::Error - Unable to send a notification for "\
              "#{appeal_state&.appeal_type} ID #{appeal_state&.appeal_id} because of #{error}")
          end
        end
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
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled_privacy_pending
        )
      # appeal status is Hearing to be Rescheduled
      else
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled
        )
      end
    # if there's a hearing scheduled
    elsif appeal_state.hearing_scheduled
      # if there's privacy act tasks pending
      # appeal status is Hearing Scheduled /  Privacy Act Pending
      if appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.hearing_scheduled_privacy_pending
        )
      # if there's no privacy act tasks pending
      # appeal status is Hearing Scheduled
      elsif !appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.hearing_scheduled
        )
      end
    # if there's no hearing scheduled and no hearing withdrawn
    elsif !appeal_state.hearing_withdrawn
      # if there's ihp tasks pending and privacy act tasks pending
      # appeal status is VSO IHP Pending / Privacy Act Pending
      if appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.ihp_pending_privacy_pending
        )
      # if there's no ihp tasks pending and there are privacy act tasks pending
      # appeal status is Privacy Act Pending
      elsif !appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.privacy_pending
        )
      # if there's no privacy acts pending and there are ihp tasks pending
      # appeal status is VSO IHP Pending
      elsif appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.ihp_pending
        )
      # if there's no privacy acts pending or ihp tasks pending
      # appeal status is Appeal Docketed
      elsif !appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending && appeal_state.appeal_docketed
        AppellantNotification.notify_appellant(
          appeal,
          "Quarterly Notification",
          Constants.QUARTERLY_STATUSES.appeal_docketed
        )
      end
    # appeal status is Appeal Docketed
    elsif appeal_state.appeal_docketed && appeal_state.hearing_withdrawn
      AppellantNotification.notify_appellant(
        appeal,
        "Quarterly Notification",
        Constants.QUARTERLY_STATUSES.appeal_docketed
      )
    end
  end
end
