# frozen_string_literal: true

require "database_cleaner-active_record"

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

  # rubocop:disable Metrics/MethodLength
  def seed
    RequestStore[:current_user] = User.system_user
    call_and_log_seed_step :clean_db

    call_and_log_seed_step Seeds::ApiKeys
    call_and_log_seed_step Seeds::Annotations
    call_and_log_seed_step Seeds::Tags

    # These must be ran before others
    call_and_log_seed_step Seeds::BusinessLineOrg
    call_and_log_seed_step Seeds::Users
    call_and_log_seed_step Seeds::Veterans
    call_and_log_seed_step Seeds::NotificationEvents
    call_and_log_seed_step Seeds::CaseDistributionLevers
    call_and_log_seed_step Seeds::CavcSelectionBasisData
    call_and_log_seed_step Seeds::CavcDecisionReasonData
    call_and_log_seed_step Seeds::Dispatch
    call_and_log_seed_step Seeds::Jobs
    call_and_log_seed_step Seeds::DecisionIssues
    call_and_log_seed_step Seeds::SanitizedJsonSeeds
    call_and_log_seed_step Seeds::BgsServiceRecordMaker
    call_and_log_seed_step Seeds::PopulateCaseflowFromVacols
    Judge.list_all
    Attorney.list_all
    call_and_log_seed_step Seeds::IssueModificationRequest
  end
  # rubocop:enable Metrics/MethodLength
end

SeedDB.new.seed
