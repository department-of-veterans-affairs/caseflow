# frozen_string_literal: true

class AppealState < CaseflowRecord
  include HasAppealUpdatedSince
  include CreatedAndUpdatedByUserConcern
  include AppealStateBelongsToPolymorphicAppealConcern

  # Purpose: Method to verify if the Appeal can receive a QuarterlyNotification
  #
  #
  # Params: None
  #
  # Response: A boolean value indicating if the Appeal can receive a QuarterlyNotification or not
  def check_appeal_status
    if appeal.nil?
      begin
        fail Caseflow::Error::AppealNotFound, "Standard Error ID: " + SecureRandom.uuid + " The appeal was unable "\
        "to be found."
      rescue Caseflow::Error::AppealNotFound => error
        Rails.logger.error("QuarterlyNotificationsJob::Error - Unable to send a notification for "\
          "#{appeal_type} ID #{appeal_id} because of #{error}")
      end
      false
    end
    true
  end

  # Purpose: Method to check appeal state for statuses and send out a notification based on
  # which statuses are turned on in the appeal state
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def quarterly_notification_status
    if check_appeal_status
      # if either there's a hearing postponed or a hearing scheduled in error
      status = check_hearing_scheduled || check_hearing_withdrawn
      status
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status if the hearing is
  # scheduled or rescheduled
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def check_hearing_scheduled
    if hearing_postponed || scheduled_in_error
      notify_appellant_hearing_rescheduled
    # if there's a hearing scheduled
    elsif hearing_scheduled
      notify_appellant_hearing_scheduled
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status if the hearing is
  # withdrawn or docketed
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def check_hearing_withdrawn
    # if there's no hearing scheduled and no hearing withdrawn
    if !hearing_withdrawn
      notify_appellant_privacy_act_pending
    # appeal status is Appeal Docketed
    elsif appeal_docketed && hearing_withdrawn
      notify_appelant_appeal_docketed
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status if the hearing is
  # rescheduled and return the status depending on the PrivacyActPending
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def notify_appellant_hearing_rescheduled
    # appeal status is Hearing to be Rescheduled / Privacy Act Pending
    if privacy_act_pending
      Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled_privacy_pending
    # appeal status is Hearing to be Rescheduled
    else
      Constants.QUARTERLY_STATUSES.hearing_to_be_rescheduled
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status if the hearing is
  # scheduled and return the status depending on the PrivacyActPending
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def notify_appellant_hearing_scheduled
    # if there's privacy act tasks pending
    # appeal status is Hearing Scheduled /  Privacy Act Pending
    if privacy_act_pending
      Constants.QUARTERLY_STATUSES.hearing_scheduled_privacy_pending
    # if there's no privacy act tasks pending
    # appeal status is Hearing Scheduled
    else
      Constants.QUARTERLY_STATUSES.hearing_scheduled
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status
  # depending on the PrivacyActPending and VSO/IHP Pending
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def notify_appellant_privacy_act_pending
    if vso_ihp_pending
      check_ihp_tasks_pending
    else
      check_privacy_acts_pending
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status
  # and return the status depending on the VSO/IHP Tasks Pending
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def check_ihp_tasks_pending
    # if there's ihp tasks pending and privacy act tasks pending
    # appeal status is VSO IHP Pending / Privacy Act Pending
    if privacy_act_pending
      Constants.QUARTERLY_STATUSES.ihp_pending_privacy_pending
    # if there's no privacy acts pending and there are ihp tasks pending
    # appeal status is VSO IHP Pending
    else
      Constants.QUARTERLY_STATUSES.ihp_pending
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status
  # and return the status depending on the Privacy Acts Pending
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def check_privacy_acts_pending
    # if there's no ihp tasks pending and there are privacy act tasks pending
    # appeal status is Privacy Act Pending
    if privacy_act_pending
      Constants.QUARTERLY_STATUSES.privacy_pending
    # if there's no privacy acts pending or ihp tasks pending
    # appeal status is Appeal Docketed
    elsif !privacy_act_pending && appeal_docketed
      Constants.QUARTERLY_STATUSES.appeal_docketed
    end
  end

  # Purpose: Method to check Quarterly Notification Appeal Status
  # and return the Appeal Docketed status
  #
  # Params: None
  #
  # Response: Status of QuarterlyNotification
  def notify_appelant_appeal_docketed
    Constants.QUARTERLY_STATUSES.appeal_docketed
  end
end
