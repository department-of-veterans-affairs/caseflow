# frozen_string_literal: true

##
# Helper to sync the decided appeals and their decision_mailed status

module SyncDecidedAppealsHelper
  VACOLS_BATCH_PROCESS_LIMIT = ENV["VACOLS_QUERY_BATCH_SIZE"] || 800

  # Syncs the decision_mailed status of Legacy Appeals with a decision made
  def sync_decided_appeals
    begin
      # Join query to retrieve Legacy AppealState ids and corresponding vacols_id
      appeal_state_ids = AppealState.legacy.where(decision_mailed: false)
        .joins(:legacy_appeal).preload(:legacy_appeal)
        .pluck(:id, :vacols_id)

      appeal_state_ids_hash = appeal_state_ids.to_h

      vacols_decision_dates = get_decision_dates(appeal_state_ids_hash.values).to_h

      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        Parallel.each(appeal_state_ids_hash, in_threads: 4) do |appeal_state_hash|
          appeal_state_id = appeal_state_hash[0]
          vacols_id = appeal_state_hash[1]
          # If there is a decision date on the VACOLS record,
          # update the decision_mailed status on the AppealState to true
          if vacols_decision_dates[vacols_id].present?
            AppealState.find(appeal_state_id).decision_mailed_appeal_state_update_action!
          end
        end
      end
    rescue StandardError => error
      Rails.logger.error("#{error.class}: #{error.message}\n#{error.backtrace}")

      # Re-raising the error so it can be caught in the NightlySyncsJob report
      raise error
    end
  end

  # Method to retrieve the decision dates from VACOLS in batches
  # params: vacols_ids
  # Returns: Hash containing the key, value pair of vacols_id, decision_date
  def get_decision_dates(vacols_ids)
    begin
      decision_dates = {}

      # Query VACOLS in batches
      vacols_ids.in_groups_of(VACOLS_BATCH_PROCESS_LIMIT.to_i) do |vacols_id|
        VACOLS::Case.where(bfkey: vacols_id).each do |vacols_record|
          decision_dates[vacols_record[:bfkey]] = vacols_record[:bfddec]
        end
      end

      decision_dates
    rescue ActiveRecord::RecordNotFound
      []
    end
  end

  def get_vacols_ids(legacy_appeal_states)
    begin
      vacols_ids = {}

      legacy_appeal_states.each do |appeal_state|
        legacy_appeal = LegacyAppeal.find(appeal_state.appeal_id)

        # Find the VACOLS record associated with the LegacyAppeal
        vacols_ids << { appeal_state.id.to_s => (legacy_appeal[:vacols_id]).to_s }
      end

      vacols_ids
    rescue ActiveRecord::RecordNotFound
      {}
    end
  end
end
