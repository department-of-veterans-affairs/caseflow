# frozen_string_literal: true

require "database_cleaner-active_record"

# because db/seeds is not in the autoload path, we must load them explicitly here
# base.rb needs to be loaded first because the other seeds inherit from it
require Rails.root.join("db/seeds/base.rb").to_s
Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }

class GenericFullSuiteSeeds
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

  def seed
    RequestStore[:current_user] = User.system_user
    # call_and_log_seed_step :clean_db

    call_and_log_seed_step Seeds::VeteransHealthAdministration
  end
end

GenericFullSuiteSeeds.new.seed
