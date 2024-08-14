# frozen_string_literal: true

##
# Helper to sync the decided appeals and their decision_mailed status

module SyncDecidedAppealsHelper
  # Syncs the decision_mailed status of Legacy Appeals with a decision made
  def sync_decided_appeals
    begin
      AppealState.legacy.where(decision_mailed: false).each do |appeal_state|
        # If there is a decision date on the VACOLS record,
        # update the decision_mailed status on the AppealState to true
        if get_decision_date(appeal_state.appeal_id).present?
          appeal_state.decision_mailed_appeal_state_update_action!
        end
      end
    rescue StandardError => error
      byebug
      Rails.logger.error("#{error.class}: #{error.message}\n#{error.backtrace}")

      # Re-raising the error so it can be caught in the NightlySyncsJob report
      raise error
    end
  end

  def get_decision_date(appeals_id)
    begin
      legacy_appeal = LegacyAppeal.find(appeals_id)

      # Find the VACOLS record associated with the LegacyAppeal
      vacols_record = VACOLS::Case.find_by_bfkey!(legacy_appeal[:vacols_id])

      # Return the decision date
      vacols_record[:bfddec]
    rescue ActiveRecord::RecordNotFound
      nil
    end
  end
end
