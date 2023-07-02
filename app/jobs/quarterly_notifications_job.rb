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
    appeal_state_ids = ama_appeal_states_of_interest.pluck(:id)

    ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
      Parallel.each(appeal_state_ids, in_threads: 8, progress: "Creating Quaterly Notifications") do |id|
        Rails.application.executor.wrap do
          RequestStore.store[:current_user] = User.system_user

          appeal_state = AppealState.find(id)
          appeal = appeal_state&.appeal

          if appeal.nil?
            log_appeal_not_found(appeal_state)
            next
          end

          begin
            send_and_log_quarterly_notification(appeal_state, appeal)
          rescue StandardError => error
            log_error("QuarterlyNotificationsJob::Error - Unable to send a notification for "\
              "#{appeal_state.appeal_type} ID #{appeal_state.appeal_id} because of #{error}")
          end
        end
      end
    end
  end

  private

  def ama_appeal_states_of_interest
    AppealState.find_by_sql(
      <<-SQL
        SELECT states.*
        FROM appeal_states states
        JOIN appeals a ON states.appeal_id = a.id AND states.appeal_type = 'Appeal'
        LEFT OUTER JOIN notifications notifs ON a."uuid"::text = notifs.appeals_id
          AND notifs.event_type = 'Quarterly Notification' AND notifs.created_at > ('2023-06-30'::date)
        WHERE states.decision_mailed IS NOT true AND states.appeal_cancelled IS NOT TRUE
        AND notifs.id IS null
      SQL
    )
  end

  def legacy_appeal_states_of_interest
    AppealState.find_by_sql(
      <<-SQL
        SELECT states.*
        FROM appeal_states states
        JOIN legacy_appeals la ON states.appeal_id = la.id AND states.appeal_type = 'LegacyAppeal'
        LEFT OUTER JOIN notifications notifs ON la.vacols_id = notifs.appeals_id
          AND notifs.event_type = 'Quarterly Notification' AND notifs.created_at > ('2023-06-30'::date)
        WHERE states.decision_mailed IS NOT true AND states.appeal_cancelled IS NOT TRUE
        AND notifs.id IS null
      SQL
    )
  end


  def send_and_log_quarterly_notification(appeal_state, appeal)
    MetricsService.record("Creating Quarterly Notification for #{appeal.class} ID #{appeal.id}",
                          name: "send_quarterly_notifications(appeal_state, appeal)") do
      send_quarterly_notifications(appeal_state, appeal)
    end
  end

  # Purpose: Method to be called with an error need to be logged to the rails logger
  #
  # Params: error_message (Expecting a string) - Message to be logged to the logger
  #
  # Response: None
  def log_error(error_message)
    Rails.logger.error(error_message)
  end

  # Purpose: Raises and logs errors whenever an appeal (AMA or Legacy) for an AppealState record cannot be located.
  #
  # Params: appeal_state (AppealState instance) - AppealState model object whose attribute will be used to populate the
  #                                                 error message with additional context.
  #
  # Response: None
  def log_appeal_not_found(appeal_state)
    begin
      fail Caseflow::Error::AppealNotFound, "Standard Error ID: " + SecureRandom.uuid + " The appeal was unable "\
      "to be found."
    rescue Caseflow::Error::AppealNotFound => error
      log_error("QuarterlyNotificationsJob::Error - Unable to send a notification for "\
        "#{appeal_state.appeal_type} ID #{appeal_state.appeal_id} because of #{error}")
    end
  end

  # Purpose: Locates AppealStates for appeals needing notifications
  #
  # Params: None
  #
  # Response: ActiveRecord relation pertaining to AppealStates that will be used to determine which appeals need
  #             notifications sent to their appellants.
  def appeal_states_of_interest
    AppealState.where(decision_mailed: false, appeal_cancelled: false)
  end

  # Purpose: Method to spawn a job that will send a notification to an appellant
  #
  # Params: appeal, status
  #
  # Response: SendNotificationJob queued to send_notification SQS queue
  def send_appellant_notifcation(appeal, status)
    AppellantNotification.notify_appellant(appeal, "Quarterly Notification", status)
  end

  def postponed_hearing_notification(appeal_state, appeal)
    status = if appeal_state.privacy_act_pending
               # Appeal status is Hearing to be Rescheduled / Privacy Act Pending
               Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled_privacy_pending
             else
               # Appeal status is Hearing to be Rescheduled
               Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled
             end

    send_appellant_notifcation(appeal, status)
  end

  def scheduled_hearing_notification(appeal_state, appeal)
    status = scheduled_hearing_status(appeal_state)

    send_appellant_notifcation(appeal, status) if status
  end

  def scheduled_hearing_status(appeal_state)
    # If there's privacy act tasks pending
    # appeal status is Hearing Scheduled /  Privacy Act Pending
    return Constants.QUARTERLY_STATUSES.hearing_scheduled_privacy_pending if appeal_state.privacy_act_pending

    return Constants.QUARTERLY_STATUSES.hearing_scheduled unless appeal_state.privacy_act_pending
  end

  def unscheduled_hearing_notification(appeal_state, appeal)
    status = unscheduled_hearing_status(appeal_state)

    send_appellant_notifcation(appeal, status) if status
  end

  def unscheduled_hearing_status(appeal_state)
    # If there's IHP tasks pending and privacy act tasks pending
    # appeal status is VSO IHP Pending / Privacy Act Pending
    return Constants.QUARTERLY_STATUSES.ihp_pending_privacy_pending if ihp_pending_privacy_pending?(appeal_state)

    # If there's no IHP tasks pending and there are privacy act tasks pending
    # appeal status is Privacy Act Pending
    return Constants.QUARTERLY_STATUSES.privacy_pending if privacy_pending?(appeal_state)

    # If there's no privacy acts pending and there are IHP tasks pending
    # appeal status is VSO IHP Pending
    return Constants.QUARTERLY_STATUSES.ihp_pending if ihp_pending?(appeal_state)

    # If there's no privacy acts pending or IHP tasks pending
    # appeal status is Appeal Docketed
    return Constants.QUARTERLY_STATUSES.appeal_docketed if unscheduled_and_docketed?(appeal_state)
  end

  def hearing_postponed_or_scheduled_in_error?(appeal_state)
    appeal_state.hearing_postponed || appeal_state.scheduled_in_error
  end

  def appeal_docketed_with_withdrawn_hearing?(appeal_state)
    appeal_state.appeal_docketed && appeal_state.hearing_withdrawn
  end

  def ihp_pending_privacy_pending?(appeal_state)
    appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending
  end

  def privacy_pending?(appeal_state)
    !appeal_state.vso_ihp_pending && appeal_state.privacy_act_pending
  end

  def ihp_pending?(appeal_state)
    appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending
  end

  def unscheduled_and_docketed?(appeal_state)
    !appeal_state.vso_ihp_pending && !appeal_state.privacy_act_pending && appeal_state.appeal_docketed
  end

  # Purpose: Method to check appeal state for statuses and send out a notification based on
  #           which statuses are turned on in the appeal state
  #
  # Params: appeal state, appeal
  #
  # Response: None
  def send_quarterly_notifications(appeal_state, appeal)
    # If either there's a hearing postponed or a hearing scheduled in error
    if hearing_postponed_or_scheduled_in_error?(appeal_state)
      return postponed_hearing_notification(appeal_state, appeal)
    end

    # If there's a hearing scheduled
    if appeal_state.hearing_scheduled
      return scheduled_hearing_notification(appeal_state, appeal)
    end

    # If there's no hearing scheduled and no hearing withdrawn
    unless appeal_state.hearing_withdrawn
      return unscheduled_hearing_notification(appeal_state, appeal)
    end

    # Appeal status is Appeal Docketed
    if appeal_docketed_with_withdrawn_hearing?(appeal_state)
      send_appellant_notifcation(appeal, Constants.QUARTERLY_STATUSES.appeal_docketed)
    end
  end
end
