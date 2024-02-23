# frozen_string_literal: true

require "database_cleaner"

# because db/seeds is not in the autoload path, we must load them explicitly here
# base.rb needs to be loaded first because the other seeds inherit from it
require Rails.root.join("db/seeds/base.rb").to_s
Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }

class SeedDB
  def clean_db
    DatabaseCleaner.clean_with(:truncation)
    cm = CacheManager.new
    CacheManager::BUCKETS.each_key { |bucket| cm.clear(bucket) }
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

  def seed # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    RequestStore[:current_user] = User.system_user
    call_and_log_seed_step :clean_db

    call_and_log_seed_step Seeds::Annotations
    call_and_log_seed_step Seeds::Tags
    # These must be ran before others
    call_and_log_seed_step Seeds::BusinessLineOrg
    call_and_log_seed_step Seeds::Users
    call_and_log_seed_step Seeds::NotificationEvents
    call_and_log_seed_step Seeds::CaseDistributionLevers
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
    # Case Distribution Seed Data
    # Creates 300+ priority cases ready for distribution
    # Warning a number are not setup correctly so cannot be used beyond
    # just distributing
    call_and_log_seed_step Seeds::PriorityDistributions
    call_and_log_seed_step Seeds::TestCaseData
    call_and_log_seed_step Seeds::CaseDistributionAuditLeverEntries
    # End of Case Distribution Seed Data
    call_and_log_seed_step Seeds::Notifications
    call_and_log_seed_step Seeds::CavcDashboardData
    call_and_log_seed_step Seeds::VbmsExtClaim
    call_and_log_seed_step Seeds::CorrespondenceTypes
    call_and_log_seed_step Seeds::PackageDocumentTypes
    call_and_log_seed_step Seeds::Correspondence
    call_and_log_seed_step Seeds::MultiCorrespondences
    call_and_log_seed_step Seeds::QueueCorrespondences
    call_and_log_seed_step Seeds::VbmsDocumentTypes
    call_and_log_seed_step Seeds::CasesTiedToJudgesNoLongerWithBoard
    call_and_log_seed_step Seeds::VhaChangeHistory
    # Always run this as last one
    call_and_log_seed_step Seeds::StaticTestCaseData
    call_and_log_seed_step Seeds::StaticDispatchedAppealsTestData
    call_and_log_seed_step Seeds::AutoTexts
    call_and_log_seed_step Seeds::RemandedAmaAppeals
    call_and_log_seed_step Seeds::RemandedLegacyAppeals
    call_and_log_seed_step Seeds::PopulateCaseflowFromVacols

    Judge.list_all
    Attorney.list_all
  end
end

SeedDB.new.seed
