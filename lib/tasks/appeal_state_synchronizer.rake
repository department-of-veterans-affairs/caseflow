# frozen_string_literal: true

namespace :appeal_state_synchronizer do
  desc "Used to synchronize appeal_states table using data from other sources."
  task sync_appeal_states: :environment do
    Rails.application.eager_load!

    adjust_legacy_hearing_statuses
    adjust_ama_hearing_statuses
    locate_unrecorded_docketed_states
    backfill_appeal_information
  end

  task sync_legacy_appeal_decisions: :environment do
    include SyncDecidedAppealsHelper

    sync_decided_appeals
  end

  def map_appeal_hearing_scheduled_state(appeal_state)
    if !appeal_state.appeal&.hearings&.empty? && appeal_state.appeal.hearings.max_by(&:scheduled_for).disposition.nil?
      return { hearing_scheduled: true }
    end

    { hearing_scheduled: false }
  end

  def map_appeal_hearing_postponed_state(appeal_state)
    if appeal_state.appeal.hearings&.max_by(&:scheduled_for)&.disposition ==
       Constants.HEARING_DISPOSITION_TYPES.postponed
      { hearing_postponed: true }
    else
      { hearing_postponed: false }
    end
  end

  def map_appeal_hearing_scheduled_in_error_state(appeal_state)
    if appeal_state.appeal.hearings&.max_by(&:scheduled_for)&.disposition ==
       Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
      { scheduled_in_error: true }
    else
      { scheduled_in_error: false }
    end
  end

  def map_appeal_hearing_withdrawn_state(appeal_state)
    if appeal_state.appeal.hearings&.max_by(&:scheduled_for)&.disposition ==
       Constants.HEARING_DISPOSITION_TYPES.cancelled
      { hearing_withdrawn: true }
    else
      { hearing_withdrawn: false }
    end
  end

  # Looks at the latest legacy hearings (in the VACOLS HEARSCHED table via the HearingRepository class)
  #  to see if a disposition was placed onto a hearing without Caseflow having registered that event.
  def adjust_legacy_hearing_statuses
    relations = [
      AppealState.eligible_for_quarterly.where(hearing_scheduled: true, appeal_type: "LegacyAppeal"),
      AppealState.eligible_for_quarterly.hearing_to_be_rescheduled.where(appeal_type: "LegacyAppeal")
    ]

    Parallel.each(relations, in_processes: 2) do |relation|
      Parallel.each(relation, in_threads: 10) do |appeal_state|
        RequestStore[:current_user] = User.system_user

        hs_state = map_appeal_hearing_scheduled_state(appeal_state)
        hp_state = map_appeal_hearing_postponed_state(appeal_state)
        sie_state = map_appeal_hearing_scheduled_in_error_state(appeal_state)
        w_state = map_appeal_hearing_withdrawn_state(appeal_state)

        appeal_state.update!([hs_state, hp_state, sie_state, w_state].inject(&:merge))
      end
    end
  end

  def locate_unrecorded_docketed_states
    appeals_missing_states = LegacyAppeal.find_by_sql(
      <<-SQL
        SELECT DISTINCT la.*
        FROM legacy_appeals la
        JOIN notifications n ON la.vacols_id = n.appeals_id AND event_type = 'Appeal docketed'
        LEFT JOIN appeal_states states ON la.id = states.appeal_id AND states.appeal_type = 'LegacyAppeal'
        WHERE states.id IS NULL
      SQL
    )

    Parallel.each(appeals_missing_states, in_threads: 10) do |appeal|
      # It's necessary to have a current user set whenever creating appeal_states records
      # as created_by_id is a required field, AND it's derived from RequestStore[:current_user]
      # in some higher environments. This must be done in each thread since a RequestStore instance's
      # contents are scoped to each thread.
      RequestStore[:current_user] = User.system_user

      appeal.appeal_state.appeal_docketed_appeal_state_update_action!
    end
  end

  def incorrect_hearing_scheduled_appeal_states_query
    <<-SQL
      SELECT DISTINCT *
      FROM appeal_states
      WHERE hearing_scheduled IS TRUE
      AND appeal_type = 'Appeal'
      AND id NOT IN (
          SELECT s.id
          FROM appeals
          INNER JOIN tasks ON appeals.id = tasks.appeal_id
          INNER JOIN hearings h ON appeals.id = h.appeal_id
          INNER JOIN appeal_states s ON s.appeal_id = appeals.id AND s.appeal_type = 'Appeal'
          WHERE tasks.appeal_type = 'Appeal'
          AND tasks.type = 'AssignHearingDispositionTask'
          AND tasks.status = 'assigned'
          AND appeals.docket_type = 'hearing'
          AND h.disposition IS NULL
      )
    SQL
  end

  def adjust_ama_hearing_statuses
    incorrect_appeal_states = AppealState.find_by_sql(incorrect_hearing_scheduled_appeal_states_query)

    Parallel.each(incorrect_appeal_states, in_threads: 10) do |state_to_correct|
      RequestStore[:current_user] = User.system_user

      state_to_correct.update!(hearing_scheduled: false)
    end
  end

  def ama_backfill_sql
    <<-SQL
      UPDATE notifications n
      SET notifiable_id = a.id,
        notifiable_type = 'Appeal'
      FROM appeals a
      WHERE n.appeals_id = a.uuid::text
    SQL
  end

  def legacy_backfill_sql
    <<-SQL
      UPDATE notifications n
      SET notifiable_id = la.id,
        notifiable_type = 'LegacyAppeal'
      FROM legacy_appeals la
      WHERE n.appeals_id = la.vacols_id
    SQL
  end

  def backfill_appeal_information
    begin
      # Temporarily Bump Up Timeout
      ActiveRecord::Base.connection.execute("SET statement_timeout = '600s'")

      ActiveRecord::Base.connection.execute(ama_backfill_sql)
      ActiveRecord::Base.connection.execute(legacy_backfill_sql)
    rescue StandardError => error
      Rails.logger.error("#{error.class}: #{error.message}\n#{error.backtrace}")
    ensure
      # Set Timeout Back
      ActiveRecord::Base.connection.execute("SET statement_timeout = '30s'")
    end
  end
end
