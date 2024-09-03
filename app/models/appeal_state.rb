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
  # @return [Array<AppealState>]
  #   Appeal states for appeals with scheduled hearings without dispositions
  scope :hearing_scheduled, lambda {
    hearing_scheduled_ama.where(
      privacy_act_pending: false
    ) + validated_hearing_scheduled_legacy_states.where(
      privacy_act_pending: false
    )
  }

  # Locates appeal states related to appeals whose hearings have been scheduled and waiting to be held.
  #  In addition, these appeals have an active Privacy Act/FOIA request in their trees.
  #
  # @return [Array<AppealState>]
  #   Appeal states for appeals with scheduled hearings without dispositions, and those appeals
  #     have open Privacy Act/FOIA-related tasks in their task trees.
  scope :hearing_scheduled_privacy_pending, lambda {
    hearing_scheduled_ama.where(
      privacy_act_pending: true
    ) + validated_hearing_scheduled_legacy_states.where(
      privacy_act_pending: true
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
  # a hearing being marked as having been held.
  #
  # Params: None
  #
  # Response: None
  def hearing_held_appeal_state_update_action!
    update!(hearing_scheduled: false)
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

  # A base set of conditions for identifying if an appeal's most recent milestone was its
  #  hearing being scheduled. This scope can be utilized for any variation on this
  #  status, such as whether or not certain mail or FOIA tasks also exist for the appeal.
  #
  # @return [AppealState::ActiveRecord_Relation]
  #   An ActiveRecord_Relation that can be changes with other AR scopes, clauses, methods, etc..
  #     in order to construct a SQL query.
  scope :hearing_scheduled_base, lambda {
    where(
      hearing_scheduled: true,
      hearing_postponed: false,
      scheduled_in_error: false
    )
  }

  # @return [AppealState::ActiveRecord_Relation]
  #   The base hearing scheduled status query scoped only to AMA appeals.
  scope :hearing_scheduled_ama, lambda {
    task_join.hearing_scheduled_base.where(appeal_type: "Appeal").with_assigned_assign_hearing_disposition_task
  }

  # @return [AppealState::ActiveRecord_Relation]
  #   The base hearing scheduled status query scoped only to legacy appeals.
  scope :hearing_scheduled_legacy_base, lambda {
    hearing_scheduled_base.where(appeal_type: "LegacyAppeal")
  }

  # Represents an inner join between the appeal_states and tasks tables. This allows for utilizing
  #   tasks to further inform us of where an appeal is in its lifecycle.
  #
  # @return [AppealState::ActiveRecord_Relation]
  #   An ActiveRecord_Relation that can be changes with other AR scopes, clauses, methods, etc..
  #     in order to construct a SQL query.
  scope :task_join, lambda {
    joins(
      "join tasks on tasks.appeal_id = appeal_states.appeal_id and tasks.appeal_type = appeal_states.appeal_type"
    )
  }

  # Represents an inner join between the appeal_states and legacy_appeals tables.
  #  This association is used to then pull relevant data from VACOLS to validate an appeal's state.
  #
  # @return [AppealState::ActiveRecord_Relation]
  #   An ActiveRecord_Relation that can be changes with other AR scopes, clauses, methods, etc..
  #     in order to construct a SQL query.
  scope :legacy_appeals_join, lambda {
    joins(
      "join legacy_appeals on legacy_appeals.id = appeal_states.appeal_id " \
      "and appeal_states.appeal_type = 'LegacyAppeal'"
    )
  }

  # A clause to enforce the need for an assigned AssignHearingDispositionTask to be
  #   associated with the same appeal as an appeal state record.
  #
  # If constraints are met, then it should mean that there is a pending hearing for the appeal
  #  that is waiting for a disposition, and therefore has not been held. This is key
  #  for us in determining which appeals are in a state of hearing_scheduled.
  #
  # At this time this task is not possible to be placed into a status of in_progress, and on_hold
  #   often means that it has a child EvidenceSubmissionWindowTask (as long as the evidence submission wasn't waived)
  #   and/or TranscriptionTask. This occurs after a hearing is held.
  #
  # @return [AppealState::ActiveRecord_Relation]
  #   An ActiveRecord_Relation that can be changes with other AR scopes, clauses, methods, etc..
  #     in order to construct a SQL query.
  scope :with_assigned_assign_hearing_disposition_task, lambda {
    where(
      "tasks.type = ? and tasks.status = ?",
      AssignHearingDispositionTask.name,
      Constants.TASK_STATUSES.assigned
    )
  }

  class << self
    # Utilizes the appeal states that we have recorded as being hearing_scheduled = true
    #  and then reaches out to VACOLS to validate that the related hearings do not yet have
    #  a disposition.
    #
    # This is to combat instances where VACOLS is updated without Caseflow's knowledge and other
    #   difficulties around synchronizing the appeals states table for legacy appeals and hearings.
    #
    # @note The in_groups_of size must not exceed 1k due to Oracle database limitations.
    #
    # @return [AppealState::ActiveRecord_Relation]
    #   Either an AR relation signifying appeal states where the hearing has been confirmed to have a pending
    #   disposition in VACOLS, or simply nothing (none). Regardless, the relation returned can be safely chained to
    #   other ActiveRecord query building methods.
    def validated_hearing_scheduled_legacy_states
      ids_to_validate = hearing_scheduled_legacy_base.legacy_appeals_join.pluck(:vacols_id)
      validated_vacols_ids = []

      ids_to_validate.in_groups_of(500, false) do |ids_to_examine|
        validated_vacols_ids.concat(VACOLS::CaseHearing.where(
          folder_nr: ids_to_examine,
          hearing_disp: nil
        ).pluck(:folder_nr))
      end

      return none if validated_vacols_ids.empty?

      where(
        appeal_type: "LegacyAppeal",
        appeal_id: LegacyAppeal.where(vacols_id: validated_vacols_ids).pluck(:id)
      )
    end
  end

  # :reek:FeatureEnvy
  def update_appeal_state_action!(status_to_update)
    update!({}.merge(DEFAULT_STATE).tap do |existing_statuses|
      existing_statuses[status_to_update] = true

      if status_to_update == :appeal_cancelled
        existing_statuses.merge!({
                                   privacy_act_complete: false,
                                   privacy_act_pending: false,
                                   appeal_docketed: false
                                 })
      end

      if status_to_update == :decision_mailed
        existing_statuses[:appeal_docketed] = false
      end
    end)
  end
end
