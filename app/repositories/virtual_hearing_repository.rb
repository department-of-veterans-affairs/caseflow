# frozen_string_literal: true

class VirtualHearingRepository
  class << self
    def ready_for_deletion
      virtual_hearings_for_ama_hearings = virtual_hearings_joined_with_hearings_and_hearing_day(Hearing)
        .eligible_for_deletion
        .where(
          "hearing_days.scheduled_for < :today OR
          hearings.disposition='postponed' OR hearings.disposition='cancelled' OR
          virtual_hearings.request_cancelled = true", today: Time.zone.today
        )

      virtual_hearings_for_legacy_hearings = virtual_hearings_joined_with_hearings_and_hearing_day(LegacyHearing)
        .eligible_for_deletion
        .where(
          "hearing_days.scheduled_for < :today OR
          legacy_hearings.vacols_id in (:postponed_or_cancelled_vacols_ids) OR
          virtual_hearings.request_cancelled = true",
          postponed_or_cancelled_vacols_ids: postponed_or_cancelled_vacols_ids, today: Time.zone.today
        )

      virtual_hearings_for_ama_hearings + virtual_hearings_for_legacy_hearings
    end

    # Get all virtual hearings that *might* need to have a reminder email sent.
    #
    # @note The logic to determine whether or not a reminder email needs to be sent is
    #   complex enough that it's not worth putting in an SQL query for maintainability reasons.
    #   This method will find all active virtual hearings that are occurring within the next 7
    #   days.
    def maybe_ready_for_reminder_email
      ama_virtual_hearings_ready_for_email = virtual_hearings_joined_with_hearings_and_hearing_day(Hearing)
        .not_cancelled
        .where(
          "hearings.disposition NOT IN (:non_active_hearing_dispositions) OR hearings.disposition IS NULL",
          non_active_hearing_dispositions: [:postponed, :cancelled]
        )
        .where(where_hearing_occurs_within_the_timeframe)

      legacy_virtual_hearings_ready_for_email = virtual_hearings_joined_with_hearings_and_hearing_day(LegacyHearing)
        .not_cancelled
        .where(where_hearing_occurs_within_the_timeframe)

      postponed_or_cancelled_legacy = postponed_or_cancelled_vacols_ids

      unless postponed_or_cancelled_legacy.empty?
        # Active Hearings
        legacy_virtual_hearings_ready_for_email = legacy_virtual_hearings_ready_for_email.where(
          "legacy_hearings.vacols_id NOT IN (:postponed_or_cancelled_vacols_ids)",
          postponed_or_cancelled_vacols_ids: postponed_or_cancelled_vacols_ids
        )
      end

      ama_virtual_hearings_ready_for_email + legacy_virtual_hearings_ready_for_email
    end

    def cancelled_hearings_with_pending_emails
      VirtualHearing
        .cancelled
        .where(pending_appellant_or_rep_emails_sql)
    end

    def hearings_with_pending_conference_or_pending_emails
      VirtualHearing
        .where(<<-SQL)
          (
            virtual_hearings.conference_id IS null
            AND virtual_hearings.host_hearing_link IS null
            AND virtual_hearings.guest_hearing_link IS null
            OR (
              #{pending_appellant_or_rep_emails_sql}
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
    def virtual_hearings_joined_with_hearings_and_hearing_day(hearing_type)
      table = hearing_type.table_name

      VirtualHearing
        .where(hearing_type: hearing_type.name)
        .joins("INNER JOIN #{table} ON #{table}.id = virtual_hearings.hearing_id")
        .joins("INNER JOIN hearing_days ON hearing_days.id = #{table}.hearing_day_id")
    end

    def postponed_or_cancelled_vacols_ids
      # Note: Limit of 1000 is a hotfix for a performance issue with this query.
      # See:
      #   - https://dsva.slack.com/archives/C3EAF3Q15/p1612211920046800
      #   - https://dsva.slack.com/archives/CHD7QU4L8/p1612278521029500
      VACOLS::CaseHearing.by_dispositions(
        [
          VACOLS::CaseHearing::HEARING_DISPOSITIONS.key("postponed"),
          VACOLS::CaseHearing::HEARING_DISPOSITIONS.key("cancelled")
        ]
      ).limit(1000).pluck(:hearing_pkseq).map(&:to_s) || []
    end

    def pending_appellant_or_rep_emails_sql
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
    def where_hearing_occurs_within_the_timeframe
      <<-SQL
        DATE_PART(
        'day',
        hearing_days.scheduled_for::timestamp - '#{Time.zone.today}'::timestamp
        ) BETWEEN 1 AND 7
      SQL
    end
  end
end
