# frozen_string_literal: true

require "database_cleaner-active_record"

# because db/seeds is not in the autoload path, we must load them explicitly here
# base.rb needs to be loaded first because the other seeds inherit from it
require Rails.root.join("db/seeds/base.rb").to_s
Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }

module Seeds
  class Optional < Base
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

    def seed!
      RequestStore[:current_user] = User.system_user

      call_and_log_seed_step Seeds::Tasks
      call_and_log_seed_step Seeds::Hearings
      call_and_log_seed_step Seeds::Intake
      call_and_log_seed_step Seeds::VeteransHealthAdministration
      call_and_log_seed_step Seeds::MTV
      call_and_log_seed_step Seeds::TestCaseData
      call_and_log_seed_step Seeds::CaseDistributionAuditLeverEntries
      call_and_log_seed_step Seeds::Notifications
      call_and_log_seed_step Seeds::CavcDashboardData
      call_and_log_seed_step Seeds::Substitutions
      call_and_log_seed_step Seeds::VbmsExtClaim
      call_and_log_seed_step Seeds::CasesTiedToJudgesNoLongerWithBoard
      call_and_log_seed_step Seeds::VhaChangeHistory
      call_and_log_seed_step Seeds::CavcAmaAppeals
      call_and_log_seed_step Seeds::AmaAffinityCases
      call_and_log_seed_step Seeds::MstPactLegacyCaseAppeals
      call_and_log_seed_step Seeds::AmaIntake
      call_and_log_seed_step Seeds::StaticTestCaseData
      call_and_log_seed_step Seeds::StaticDispatchedAppealsTestData
      call_and_log_seed_step Seeds::RemandedAmaAppeals
      call_and_log_seed_step Seeds::RemandedLegacyAppeals
    end
  end
end
