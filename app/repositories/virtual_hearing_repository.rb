# frozen_string_literal: true

class VirtualHearingRepository
  class << self
    def ready_for_deletion
      virtual_hearings_for_ama_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: Hearing.name)
        .joins("INNER JOIN hearings ON hearings.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = hearings.hearing_day_id")
        .where(
          "hearing_days.scheduled_for < :today OR virtual_hearings.status = :status",
          today: Time.zone.today,
          status: :cancelled
        )

      virtual_hearings_for_legacy_hearings = VirtualHearing.eligible_for_deletion
        .where(hearing_type: LegacyHearing.name)
        .joins("INNER JOIN legacy_hearings ON legacy_hearings.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = legacy_hearings.hearing_day_id")
        .where(
          "hearing_days.scheduled_for < :today OR virtual_hearings.status = :status",
          today: Time.zone.today,
          status: :cancelled
        )

      virtual_hearings_for_ama_hearings + virtual_hearings_for_legacy_hearings
    end

    def cancelled_hearings_with_pending_emails
      VirtualHearing
        .cancelled
        .where(<<-SQL, false, false, false)
          (
            virtual_hearings.judge_email_sent = ?
            OR virtual_hearings.veteran_email_sent = ?
            OR (
              NOT virtual_hearings.representative_email = null
              AND virtual_hearings.representative_email = ?
            )
          )
        SQL
    end
  end
end
