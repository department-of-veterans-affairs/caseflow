# frozen_string_literal: true

class CheckVeteranResidenceLocationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  RESIDENCE_LOCATION_PROCESS_LIMIT = ENV["RESIDENCE_LOCATION_BATCH_SIZE"].to_i || 5000
  VET_UPDATE_BATCH_PROCESS_LIMIT = ENV["VET_UPDATE_BATCH_SIZE"].to_i || 100

  def perform
    ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
      vets_semaphore = Mutex.new
      vet_updates = []

      # Setting up parallel threads to retrieve and process all the veteran residence details
      Parallel.each(retrieve_veterans, in_threads: 4) do |veteran|
        begin
          ensure_current_user_is_set

          residence_updates = { id: veteran.id, state_of_residence: veteran.address.state,
                                country_of_residence: veteran.address.country,
                                residence_location_last_checked_at: Time.zone.now }

          # Adding all the veteran updates to a common object between all the threads
          vets_semaphore.synchronize do
            vet_updates << residence_updates
          end
        rescue StandardError => error
          log_error(error)
        end
      end

      batch_update_veterans(vet_updates)
    end
  end

  def retrieve_veterans
    begin
      # Retrieves all the Veteran entries where there is no residence information,
      # or where the residence information was last checked over a week ago
      check_veteran_residence = Veteran.where(state_of_residence: nil, country_of_residence: nil).or(
        Veteran.where("residence_location_last_checked_at >= ?", 1.week.ago)
      ).limit(RESIDENCE_LOCATION_PROCESS_LIMIT)

      check_veteran_residence
    rescue StandardError => error
      log_error(error)
    end
  end

  def batch_update_veterans(vet_updates)
    begin
      # Update the Veteran table in batches
      vet_updates.in_groups_of(VET_UPDATE_BATCH_PROCESS_LIMIT, false) do |batch|
        updated_vet_hash = batch.index_by { |vet| vet[:id] }
        Veteran.update(updated_vet_hash.keys, updated_vet_hash.values)
      end
    rescue StandardError => error
      log_error(error)
    end
  end
end
