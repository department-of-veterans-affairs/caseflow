# frozen_string_literal: true

class AppealState < CaseflowRecord
  include HasAppealUpdatedSince
  include CreatedAndUpdatedByUserConcern
  include AppealStateBelongsToPolymorphicAppealConcern

  # Purpose: Default state of a hash of attributes for an appeal_state, all set to false.
  #          This will be used in the `update_appeal_state` method.
  DEFAULT_STATE = {
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
    appeal_cancelled: false
  }

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
      notify_appellant_ihp_or_privacy_act_pending
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
  def notify_appellant_ihp_or_privacy_act_pending
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

  # Public: Updates/creates appeal state based on event type
  #
  # event - The module that is being triggered to send a notification
  #
  # Examples
  #
  #  AppellantNotification.update_appeal_state("hearing_postponed")
  #   # => A new appeal state is created if it doesn't exist
  #   or the existing appeal state is updated, then appeal_state.hearing_postponed becomes true
  # rubocop:disable Metrics/MethodLength, Metrics/CyclomaticComplexity
  def process_event_to_update_appeal_state!(event)
    case event
      when "decision_mailed"
        decision_mailed_appeal_state_update_action!
      when "appeal_docketed"
        appeal_docketed_appeal_state_update_action!
      when "appeal_cancelled"
        appeal_cancelled_appeal_state_update_action!
      when "hearing_postponed"
        hearing_postponed_appeal_state_update_action!
      when "hearing_withdrawn"
        hearing_withdrawn_appeal_state_update_action!
      when "hearing_scheduled"
        hearing_scheduled_appeal_state_update_action!
      when "scheduled_in_error"
        scheduled_in_error_appeal_state_update_action!
      when "vso_ihp_pending"
        vso_ihp_pending_appeal_state_update_action!
      when "vso_ihp_cancelled"
        vso_ihp_cancelled_appeal_state_update_action!
      when "vso_ihp_complete"
        # Only updates appeal state if ALL ihp tasks are completed
        vso_ihp_complete_appeal_state_update_action!
      when "privacy_act_pending"
        privacy_act_pending_appeal_state_update_action!
      when "privacy_act_complete"
        # Only updates appeal state if ALL privacy act tasks are completed
        privacy_act_complete_appeal_state_update_action!
      when "privacy_act_cancelled"
        # Only updates appeal state if ALL privacy act tasks are completed
        privacy_act_cancelled_appeal_state_update_action!
    end
  end

  private

  def update_appeal_state_action!(new_state)
    update!(DEFAULT_STATE.clone.tap { |state| state[new_state] = true })
  end

  # Purpose: Method to update appeal_state in the case of
  # a mailed decision.
  #
  # Params: appeal_state
  #
  # Response: None

  def decision_mailed_appeal_state_update_action!
    update_appeal_state_action!(:decision_mailed)
  end

  # Purpose: Method to update appeal_state in the case of
  # a cancelled appeal.
  #
  # Params: appeal_state
  #
  # Response: None
  def appeal_cancelled_appeal_state_update_action!
    update_appeal_state_action!(:appeal_cancelled)
  end

  # Purpose: Method to update appeal_state in the case of
  # a completed informal hearing presentaiton(IHP).
  #
  # Params: None
  #
  # Response: None
  def vso_ihp_complete_appeal_state_update_action!
    if appeal.tasks.open.where(type: IhpColocatedTask.name).empty? &&
       appeal.tasks.open.where(type: InformalHearingPresentationTask.name).empty?
      update_appeal_state_action!(:vso_ihp_complete)
    end
  end

  # Purpose: Move the conditional of the appeal state
  # update action into it's own method
  #
  # Params: None
  #
  # Response: None
  def privacy_act_appeal_state_update_action_conditional!
    open_tasks = appeal.tasks.open
    open_tasks.where(type: FoiaColocatedTask.name).empty? &&
    open_tasks.where(type: PrivacyActTask.name).empty? &&
    open_tasks.where(type: HearingAdminActionFoiaPrivacyRequestTask.name).empty? &&
    open_tasks.where(type: FoiaRequestMailTask.name).empty? &&
    open_tasks.where(type: PrivacyActRequestMailTask.name).empty?
  end

  # Purpose: Method to update appeal_state in the case of
  # a privacy related tasks marked as complete.
  #
  # Params: None
  #
  # Response: None
  def privacy_act_complete_appeal_state_update_action!
    if privacy_act_appeal_state_update_action_conditional!
      update_appeal_state_action!(:privacy_act_complete)
    end
  end

  # Purpose: Method to update appeal_state in the case of
  # privacy related tasks being cancelled.
  #
  # Params: None
  #
  # Response: None
  def privacy_act_cancelled_appeal_state_update_action!
    if privacy_act_appeal_state_update_action_conditional!
      update!(privacy_act_pending: false)
    end
  end

  # Purpose: Method to update appeal_state in the case of
  # a docketed appeal.
  #
  # Params: None
  #
  # Response: None
  def appeal_docketed_appeal_state_update_action!
    update_appeal_state_action!(:appeal_docketed)
  end

  # Purpose: Method to update appeal_state in the case of
  # a hearing being postponed.
  #
  # Params: None
  #
  # Response: None
  def hearing_postponed_appeal_state_update_action!
    update_appeal_state_action!(:hearing_postponed)
  end

  # Purpose: Method to update appeal_state in the case of
  # a hearing being withdrawn.
  #
  # Params: None
  #
  # Response: None
  def hearing_withdrawn_appeal_state_update_action!
    update_appeal_state_action!(:hearing_withdrawn)
  end

  # Purpose: Method to update appeal_state in the case of
  # a hearing being scheduled.
  #
  # Params: None
  #
  # Response: None
  def hearing_scheduled_appeal_state_update_action!
    update_appeal_state_action!(:hearing_scheduled)
  end

  # Purpose: Method to update appeal_state in the case of
  # a hearing being scheduled in error.
  #
  # Params: None
  #
  # Response: None
  def scheduled_in_error_appeal_state_update_action!
    update_appeal_state_action!(:scheduled_in_error)
  end

  # Purpose: Method to update appeal_state in the case of
  # the most recent VSO IHP Organizational task in the task
  # tree being in an opened state.
  #
  # Params: None
  #
  # Response: None
  def vso_ihp_pending_appeal_state_update_action!
    update_appeal_state_action!(:vso_ihp_pending)
  end

  # Purpose: Method to update appeal_state in the case of
  # the most recent VSO IHP Organizational task in the task
  # tree being cancelled.
  #
  # Params: None
  #
  # Response: None
  def vso_ihp_cancelled_appeal_state_update_action!
    update!(vso_ihp_pending: false, vso_ihp_complete: false)
  end

  # Purpose: Method to update appeal_state in the case of
  # there being at least one of the privacy act related
  # tasks is still in an opened status.
  #
  # Params: None
  #
  # Response: None
  def privacy_act_pending_appeal_state_update_action!
    update_appeal_state_action!(:privacy_act_pending)
  end
end
