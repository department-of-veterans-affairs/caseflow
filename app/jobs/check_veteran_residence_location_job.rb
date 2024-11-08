# frozen_string_literal: true

class CheckVeteranResidenceLocationJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  RESIDENCE_LOCATION_PROCESS_LIMIT = ENV["RESIDENCE_LOCATION_BATCH_SIZE"].to_i || 5000
  VET_UPDATE_BATCH_PROCESS_LIMIT = ENV["VET_UPDATE_BATCH_SIZE"].to_i || 100

  def perform
    begin
      byebug
      # Retrieves all the Veteran entries where there is no residence information,
      # or where the residence information was last checked over a week ago
      check_veteran_residence = Veteran.where(state_of_residence: nil,
      country_of_residence: nil
      ).or(
        Veteran.where(residence_location_last_checked_at: ..1.hour.ago)
      ).limit(RESIDENCE_LOCATION_PROCESS_LIMIT)

      ActiveSupport::Dependencies.interlock.permit_concurrent_loads do
        vets_semaphore = Mutex.new
        vet_updates = []

        # Setting up parallel threads to retrieve and process all the veteran residence details
        Parallel.each(check_veteran_residence, in_threads: 4) do |veteran|
          begin
            ensure_current_user_is_set

            residence_updates = {id: veteran.id}
            residence_updates[:state_of_residence] = veteran.address.state
            residence_updates[:country_of_residence] = veteran.address.country
            residence_updates[:residence_location_last_checked_at] = Time.now

            # Adding all the veteran updates to a common object between all the threads
            vets_semaphore.synchronize {
              vet_updates << residence_updates
            }
          rescue StandardError => error
            log_error(error)
          end
        end

        # Update the Veteran table in batches
        vet_updates.in_groups_of(VET_UPDATE_BATCH_PROCESS_LIMIT, false) do |batch|
          updated_vet_hash = batch.index_by { |vet| vet[:id] }
          Veteran.update(updated_vet_hash.keys, updated_vet_hash.values)
        end

      end
    rescue StandardError => error
      log_error(error)
    end
  end
end
