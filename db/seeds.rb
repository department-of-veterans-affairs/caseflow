# frozen_string_literal: true

require "database_cleaner"

# because db/seeds is not in the autoload path, we must load them explicitly here
Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }

class SeedDB
  def clean_db
    DatabaseCleaner.clean_with(:truncation)
    cm = CacheManager.new
    CacheManager::BUCKETS.keys.each { |bucket| cm.clear(bucket) }
    Fakes::EndProductStore.new.clear!
    Fakes::RatingStore.new.clear!
    Fakes::VeteranStore.new.clear!
  end

  def call_and_log_seed_step(step)
    msg = "Starting seed step #{step}"
    Rails.logger.debug(msg)

    if step.is_a?(Symbol)
      send(step)
    else
      step.new.seed!
    end

    msg = "Finished seed step #{step}"
    Rails.logger.debug(msg)
  end

  def seed
    call_and_log_seed_step :clean_db

    call_and_log_seed_step Seeds::Annotations
    call_and_log_seed_step Seeds::Tags
    call_and_log_seed_step Seeds::Users # TODO must run this before others

    # Updates to the updated_by database fields use the current_user from the RequestStore,
    # so log in as the system_user so that all attempts to create records with updated_by
    # fields succeed even if we don't have a user in the RequestStore yet.
    RequestStore.store[:current_user] = User.system_user

    call_and_log_seed_step Seeds::Tasks
    call_and_log_seed_step Seeds::Hearings
    call_and_log_seed_step Seeds::Intake
    call_and_log_seed_step Seeds::Dispatch
    call_and_log_seed_step Seeds::Jobs
    call_and_log_seed_step Seeds::Substitutions
    call_and_log_seed_step Seeds::DecisionIssues
    call_and_log_seed_step Seeds::CavcAmaAppeals
    call_and_log_seed_step Seeds::SanitizedJsonSeeds
    call_and_log_seed_step Seeds::MTV
    call_and_log_seed_step Seeds::VeteransHealthAdministration
  end
end

SeedDB.new.seed
