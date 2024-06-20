# frozen_string_literal: true

# == Overview
#
# AppealState records are utilized to facilitate state machine-like behavior in order
# to track which status each appeal (AMA and Legacy) being processed in Caseflow is in.
#
# These states are most prominently used in the determination of which status to place in the
# 'Quarterly Notification' template whenever sending the quarterly correspondence to appellants.
# This is performed by the QuarterlyNotificationsJob.
class AppealState < CaseflowRecord
  include HasAppealUpdatedSince
  include CreatedAndUpdatedByUserConcern
  include AppealStateBelongsToPolymorphicAppealConcern

  # Purpose: Default state of a hash of attributes for an appeal_state, all set to false.
  #          This will be used in the `update_appeal_state` method.
  DEFAULT_STATE = ActiveSupport::HashWithIndifferentAccess.new(decision_mailed: false,
                                                               appeal_docketed: false,
                                                               hearing_postponed: false,
                                                               hearing_withdrawn: false,
                                                               hearing_scheduled: false,
                                                               vso_ihp_pending: false,
                                                               vso_ihp_complete: false,
                                                               scheduled_in_error: false,
                                                               appeal_cancelled: false).freeze

  # Locates appeal states that are related to appeals eligible to potentially receive quarterly notifications.
  #   These appeals must not have been cancelled and their decisions must not have already been mailed.
  #
  # @return [ActiveRecord::Relation]
  #   Appeals eligible (potentially, assuming claimant is listed and claimant doesn't have an NOD on file)
  #    to receive a quarterly notification.
  scope :eligible_for_quarterly, lambda {
    where(
      appeal_cancelled: false,
      decision_mailed: false
    )
  }

  # Locates appeal states related to appeals whose hearings have been cancelled
  #   (postponed or marked as "scheduled in error") and have yet to be rescheduled.
  #
  # @return [ActiveRecord::Relation]
  #   Appeal states for appeals with hearings awaiting reschedulement.
  scope :hearing_to_be_rescheduled, lambda {
    where(
      <<~SQL
          hearing_scheduled IS FALSE AND
          privacy_act_pending IS FALSE AND
        (
          hearing_postponed IS TRUE OR
          scheduled_in_error IS TRUE
        )
      SQL
    )
  }

  # Locates appeal states related to appeals whose hearings have been cancelled
  #   (postponed or marked as "scheduled in error") and have yet to be rescheduled.
  #   In addition, these appeals have an active Privacy Act/FOIA request in their trees.
  #
  # @return [ActiveRecord::Relation]
  #   Appeal states for appeals with hearings awaiting reschedulement with Privacy Act/FOIA tasks.
  scope :hearing_to_be_rescheduled_privacy_pending, lambda {
    where(
      <<~SQL
        hearing_scheduled IS FALSE AND
        privacy_act_pending IS TRUE AND
        (
          hearing_postponed IS TRUE OR
          scheduled_in_error IS TRUE
        )
      SQL
    )
  }

  # Locates appeal states related to appeals whose hearings have been scheduled and waiting to be held.
  #
  # @return [ActiveRecord::Relation]
  #   Appeal states for appeals with scheduled hearings without dispositions
  scope :hearing_scheduled, lambda {
    where(
      hearing_scheduled: true,
      privacy_act_pending: false,
      hearing_postponed: false,
      scheduled_in_error: false
    )
  }

  # Locates appeal states related to appeals whose hearings have been scheduled and waiting to be held.
  #  In addition, these appeals have an active Privacy Act/FOIA request in their trees.
  #
  # @return [ActiveRecord::Relation]
  #   Appeal states for appeals with scheduled hearings without dispositions, and those appeals
  #     have open Privacy Act/FOIA-related tasks in their task trees.
  scope :hearing_scheduled_privacy_pending, lambda {
    where(
      hearing_scheduled: true,
      privacy_act_pending: true,
      hearing_postponed: false,
      scheduled_in_error: false
    )
  }

  # Locates appeal states related to appeals with open InformalHearingPresentationTasks.
  #  In addition, these appeals have an open Privacy Act/FOIA request-related tasks in their trees.
  #
  # @return [ActiveRecord::Relation]
  #   Appeal states for appeals with open InformalHearingPresentationTasks.
  #     have open Privacy Act/FOIA-related tasks in their task trees.
  scope :ihp_pending_privacy_pending, lambda {
    where(
      vso_ihp_pending: true,
      privacy_act_pending: true,
      hearing_scheduled: false,
      hearing_postponed: false,
      scheduled_in_error: false,
      hearing_withdrawn: false
    )
  }

  # Locates appeal states related to appeals with open InformalHearingPresentationTasks.
  #
  # @return [ActiveRecord::Relation]
  #   Appeal states for appeals with open InformalHearingPresentationTasks.
  scope :ihp_pending, lambda {
    where(
      vso_ihp_pending: true,
      privacy_act_pending: false,
      hearing_scheduled: false,
      hearing_postponed: false,
      scheduled_in_error: false,
      hearing_withdrawn: false
    )
  }

  # Locates appeal states related to appeals with open Privacy Act/FOIA request-related tasks in their trees,
  #   however no other actions have taken place on the appeal (aside from perhaps docketing).
  #
  # @return [ActiveRecord::Relation]
  #  Appeal states for appeals with open Privacy Act/FOIA request-related tasks
  scope :privacy_pending, lambda {
    where(
      vso_ihp_pending: false,
      privacy_act_pending: true,
      hearing_scheduled: false,
      hearing_postponed: false,
      scheduled_in_error: false,
      hearing_withdrawn: false
    )
  }

  # Locates appeal states related to appeals that have either just been docketed, or have had their hearing withdrawn
  #  causing them to return to their initial state.
  #
  # @return [ActiveRecord::Relation]
  #  Appeal states for appeals that have been docketed and are awaiting further action.
  scope :appeal_docketed, lambda {
    where(
      <<~SQL
        appeal_docketed IS TRUE AND
        hearing_postponed IS FALSE AND
        scheduled_in_error IS FALSE AND
        hearing_scheduled IS FALSE AND
        (
          (
            hearing_withdrawn IS FALSE AND
            vso_ihp_pending IS FALSE AND
            privacy_act_pending IS FALSE
          ) OR (
            hearing_withdrawn IS TRUE
          )
        )
      SQL
    )
  }

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
  # Params: appeal
  # Params: None
  #
  # Response: None
  def vso_ihp_complete_appeal_state_update_action!
    if !appeal.active_vso_ihp_task?
      update_appeal_state_action!(:vso_ihp_complete)
    end
  end

  # Purpose: Method to update appeal_state in the case of
  # a privacy related tasks marked as complete.
  #
  # Params: appeal
  # Params: None
  #
  # Response: None
  def privacy_act_complete_appeal_state_update_action!
    unless appeal.active_foia_task?
      update!(privacy_act_pending: false, privacy_act_complete: true)
    end
  end

  # Purpose: Method to update appeal_state in the case of
  # privacy related tasks being cancelled.
  #
  # Params: appeal
  # Params: None
  #
  # Response: None
  def privacy_act_cancelled_appeal_state_update_action!
    unless appeal.active_foia_task?
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
    update!(privacy_act_pending: true, privacy_act_complete: false)
  end

  private

  def update_appeal_state_action!(status_to_update)
    update!({}.merge(DEFAULT_STATE).tap do |existing_statuses|
      existing_statuses[status_to_update] = true

      if status_to_update == :appeal_cancelled
        existing_statuses.merge({
                                  privacy_act_complete: false,
                                  privacy_act_pending: false
                                })
      end
    end)
  end
end
