# frozen_string_literal: true

class AppealState < CaseflowRecord
  include HasAppealUpdatedSince
  include CreatedAndUpdatedByUserConcern
  include AppealStateBelongsToPolymorphicAppealConcern

  scope :eligible_for_quarterly, lambda {
    where(
      appeal_cancelled: false,
      decision_mailed: false
    )
  }

  scope :hearing_to_be_rescheduled, lambda {
    where("""
      hearing_scheduled IS FALSE AND
      privacy_act_pending IS FALSE AND
      (
        hearing_postponed IS TRUE OR
        scheduled_in_error IS TRUE
      )
    """)
  }

  scope :hearing_to_be_rescheduled_privacy_pending, lambda {
    where("""
      hearing_scheduled IS FALSE AND
      privacy_act_pending IS TRUE AND
      (
        hearing_postponed IS TRUE OR
        scheduled_in_error IS TRUE
      )
    """)
  }

  scope :hearing_scheduled, lambda {
    where(
      hearing_scheduled: true,
      privacy_act_pending: false,
      hearing_postponed: false,
      scheduled_in_error: false
    )
  }

  scope :hearing_scheduled_privacy_pending, lambda {
    where(
      hearing_scheduled: true,
      privacy_act_pending: true,
      hearing_postponed: false,
      scheduled_in_error: false
    )
  }

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

  scope :appeal_docketed, lambda {
    where("""
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
    """)
  }
end
