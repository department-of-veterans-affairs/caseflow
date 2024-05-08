# frozen_string_literal: true

class AppellantNotificationService

# This service will be instantiated with and appeal object and an appeal_state object
  def initialize(appeal, appeal_state)
    @appeal = appeal
    @appeal_state = appeal_state
  end

#
  def decision_mailed_appeal_state_update_action(appeal_state)
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
  end

  def appeal_cancelled_appeal_state_update_action(appeal_state)
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
  end

  def vso_ihp_complete_appeal_state_update_action(appeal, appeal_state)
    if appeal.tasks.open.where(type: IhpColocatedTask.name).empty? &&
    appeal.tasks.open.where(type: InformalHearingPresentationTask.name).empty?
      appeal_state.update!(vso_ihp_complete: true, vso_ihp_pending: false)
    end
  end

  def privacy_act_complete_appeal_state_update(appeal, appeal_state)
    open_tasks = appeal.tasks.open
      if open_tasks.where(type: FoiaColocatedTask.name).empty? && open_tasks.where(type: PrivacyActTask.name).empty? &&
      open_tasks.where(type: HearingAdminActionFoiaPrivacyRequestTask.name).empty? && open_tasks.where(type: FoiaRequestMailTask.name).empty? &&
      open_tasks.where(type: PrivacyActRequestMailTask.name).empty?
        appeal_state.update!(privacy_act_complete: true, privacy_act_pending: false)
      end
  end

  def privacy_act_cancelled_appeal_state_update(appeal, appeal_state)
    open_tasks = appeal.tasks.open
      if open_tasks.where(type: FoiaColocatedTask.name).empty? && open_tasks.where(type: PrivacyActTask.name).empty? &&
      open_tasks.where(type: HearingAdminActionFoiaPrivacyRequestTask.name).empty? && open_tasks.where(type: FoiaRequestMailTask.name).empty? &&
      open_tasks.where(type: PrivacyActRequestMailTask.name).empty?
        appeal_state.update!(privacy_act_pending: false)
      end
  end

  def appeal_docketed_appeal_state_update(appeal_state)
    appeal_state.update!(appeal_docketed: true)
  end

  def hearing_postponed_appeal_state_update_action(appeal_state)
    appeal_state.update!(hearing_postponed: true, hearing_scheduled: false)
  end

  def hearing_withdrawn_appeal_state_update_action(appeal_state)
    appeal_state.update!(hearing_withdrawn: true, hearing_postponed: false, hearing_scheduled: false)
  end

  def hearing_scheduled_appeal_state_update_action(appeal_state)
    appeal_state.update!(hearing_scheduled: true, hearing_postponed: false, scheduled_in_error: false)
  end

  def scheduled_in_error_appeal_state_update_action(appeal_state)
    appeal_state.update!(scheduled_in_error: true, hearing_scheduled: false)
  end

  def vso_ihp_pending_appeal_state_update_action(appeal_state)
    appeal_state.update!(vso_ihp_pending: true, vso_ihp_complete: false)
  end

  def vso_ihp_cancelled_appeal_state_update_action(appeal_state)
    appeal_state.update!(vso_ihp_pending: false, vso_ihp_complete: false)
  end

  def privacy_act_pending_appeal_state_update_action(appeal_state)
    appeal_state.update!(privacy_act_pending: true, privacy_act_complete: false)
  end
end
