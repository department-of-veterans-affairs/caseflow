# frozen_string_literal: true

class VirtualHearingRepository
  class TooManyVacolsIdsPassed < StandardError; end

  class << self
    # Get all virtual hearings that can have their conference deleted.
    def ready_for_deletion
      ama_ready = joins_hearing_and_hearing_day(Hearing)
        .eligible_for_deletion
        .where(
          "hearing_days.scheduled_for < :today OR hearings.disposition='scheduled_in_error' OR
          hearings.disposition='postponed' OR hearings.disposition='cancelled' OR
          virtual_hearings.request_cancelled = true", today: Time.zone.today
        )

      legacy_ready = []

      # VACOLS can support a max of 1000 at a time which is the in_batches default
      joins_hearing_and_hearing_day(LegacyHearing).eligible_for_deletion.in_batches do |vhs|
        vacols_ids = vhs.pluck("legacy_hearings.vacols_id")
        # the subset of hearings that are postponed or cancelled in VACOLS
        selected_vacols_ids = vacols_select_postponed_or_cancelled(vacols_ids)
        legacy_ready << vhs
          .where(
            "hearing_days.scheduled_for < :today OR
            legacy_hearings.vacols_id in (:postponed_or_cancelled_vacols_ids) OR
            virtual_hearings.request_cancelled = true",
            postponed_or_cancelled_vacols_ids: selected_vacols_ids, today: Time.zone.today
          ).to_a
      end

      ama_ready + legacy_ready.flatten
    end

    # Get all virtual hearings that *might* need to have a reminder email sent.
    #
    # @note The logic to determine whether or not a reminder email needs to be sent is
    #   complex enough that it's not worth putting in an SQL query for maintainability reasons.
    #   This method will find all active virtual hearings that are occurring within the next 7
    #   days.
    def maybe_ready_for_reminder_email
      ama_ready = joins_hearing_and_hearing_day(Hearing)
        .not_cancelled
        .where(
          "hearings.disposition NOT IN (:non_active_hearing_dispositions) OR hearings.disposition IS NULL",
          non_active_hearing_dispositions: [:postponed, :cancelled]
        )
        .where(scheduled_within_seven_days)

      legacy_ready = []

      # VACOLS can support a max of 1000 at a time which is the in_batches default
      joins_hearing_and_hearing_day(LegacyHearing).not_cancelled.where(scheduled_within_seven_days).in_batches do |vhs|
        vacols_ids = vhs.pluck("legacy_hearings.vacols_id")
        # the subset of hearings that are postponed or cancelled in VACOLS
        # default to [""] if empty so the NOT IN clause in the query below will work
        selected_vacols_ids = vacols_select_postponed_or_cancelled(vacols_ids).presence || [""]
        legacy_ready << vhs
          .where(
            "legacy_hearings.vacols_id NOT IN (:postponed_or_cancelled_vacols_ids)",
            postponed_or_cancelled_vacols_ids: selected_vacols_ids
          ).to_a
      end

      ama_ready + legacy_ready.flatten
    end

    def cancelled_with_pending_emails
      VirtualHearing
        .cancelled
        .where(pending_appellant_or_rep_emails)
    end

    def with_pending_conference_or_emails
      VirtualHearing
        .where(<<-SQL)
          (
            virtual_hearings.conference_id IS null
            AND virtual_hearings.host_hearing_link IS null
            AND virtual_hearings.guest_hearing_link IS null
            OR (
              #{pending_appellant_or_rep_emails}
              OR (
                virtual_hearings.judge_email IS NOT null
                AND NOT virtual_hearings.judge_email_sent
              )
            )
          )
        SQL
    end

    private

    # Returns virtual hearings joined with either the legacy hearing or hearings table,
    # and joined with the hearing day table.
    def joins_hearing_and_hearing_day(hearing_type)
      table = hearing_type.table_name

      VirtualHearing
        .where(hearing_type: hearing_type.name)
        .joins("INNER JOIN #{table} ON #{table}.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = #{table}.hearing_day_id")
    end

    # Accepts a list of legacy hearing VACOLS ids, and queries VACOLS to return the
    # subset that are associated with legacy hearings with "postponed" or "cancelled"
    # status.
    #
    # @note Cannot accept more than 1000 ids due to a limit in the VACOLS database.
    def vacols_select_postponed_or_cancelled(vacols_ids = [])
      fail TooManyVacolsIdsPassed if vacols_ids.length > 1000

      VACOLS::CaseHearing.by_dispositions(
        [
          VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:postponed],
          VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:cancelled],
          VACOLS::CaseHearing::HEARING_DISPOSITION_CODES[:scheduled_in_error]
        ]
      ).where(hearing_pkseq: vacols_ids).pluck(:hearing_pkseq).map(&:to_s) || []
    end

    def pending_appellant_or_rep_emails
      <<-SQL
        NOT virtual_hearings.appellant_email_sent
        OR (
          virtual_hearings.representative_email IS NOT null
          AND NOT virtual_hearings.representative_email_sent
        )
      SQL
    end

    # Returns a where clause that can be used to find all hearings that occur within
    # a given timeframe (in days).
    #
    # @note Requires a join with the `hearing_days` table.
    def scheduled_within_seven_days
      <<-SQL
        DATE_PART(
        'day',
        hearing_days.scheduled_for::timestamp - '#{Time.zone.today}'::timestamp
        ) BETWEEN 1 AND 7
      SQL
    end
  end
end
