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

  # In development environments this log goes to
  # caseflow/log/development.log
  def call_and_log_seed_step(step)
    msg = "Starting seed step #{step} at #{Time.zone.now.strftime('%m/%d/%Y %H:%M:%S')}"
    Rails.logger.debug(msg)

    if step.is_a?(Symbol)
      send(step)
    else
      step.new.seed!
    end

    msg = "Finished seed step #{step} at #{Time.zone.now.strftime('%m/%d/%Y %H:%M:%S')}"
    Rails.logger.debug(msg)
  end

  def seed
    RequestStore[:current_user]=User.system_user
    call_and_log_seed_step :clean_db

    call_and_log_seed_step Seeds::Annotations
    call_and_log_seed_step Seeds::Tags
    # These must be ran before others
    call_and_log_seed_step Seeds::Users
    call_and_log_seed_step Seeds::NotificationEvents
    # End of required to exist dependencies
    call_and_log_seed_step Seeds::Tasks
    call_and_log_seed_step Seeds::Hearings
    call_and_log_seed_step Seeds::Intake
    call_and_log_seed_step Seeds::Dispatch
    call_and_log_seed_step Seeds::Jobs
    call_and_log_seed_step Seeds::Substitutions
    call_and_log_seed_step Seeds::DecisionIssues
    call_and_log_seed_step Seeds::CavcAmaAppeals
    call_and_log_seed_step Seeds::SanitizedJsonSeeds
    call_and_log_seed_step Seeds::VeteransHealthAdministration
    call_and_log_seed_step Seeds::MTV
    call_and_log_seed_step Seeds::Education
    call_and_log_seed_step Seeds::PriorityDistributions
    call_and_log_seed_step Seeds::TestCaseData
    call_and_log_seed_step Seeds::Notifications
    call_and_log_seed_step Seeds::CavcDashboardData
    call_and_log_seed_step Seeds::VbmsExtClaim
    # Always run this as last one
    call_and_log_seed_step Seeds::StaticTestCaseData
    call_and_log_seed_step Seeds::StaticDispatchedAppealsTestData
    call_and_log_seed_step Seeds::BGSServiceRecordMaker
  end
end

SeedDB.new.seed
