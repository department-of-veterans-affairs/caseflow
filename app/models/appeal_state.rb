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
end
