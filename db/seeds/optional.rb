# frozen_string_literal: true

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

    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def seed!
      RequestStore[:current_user] = User.system_user

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
      call_and_log_seed_step Seeds::CasesTiedToJudgesNoLongerWithBoard
      call_and_log_seed_step Seeds::VhaChangeHistory
      call_and_log_seed_step Seeds::BgsServiceRecordMaker
      call_and_log_seed_step Seeds::MstPactLegacyCaseAppeals
      call_and_log_seed_step Seeds::AmaIntake
      call_and_log_seed_step Seeds::AmaAffinityCases
      # Always run this as last one
      call_and_log_seed_step Seeds::StaticTestCaseData
      call_and_log_seed_step Seeds::StaticDispatchedAppealsTestData
      call_and_log_seed_step Seeds::RemandedAmaAppeals
      call_and_log_seed_step Seeds::RemandedLegacyAppeals
      call_and_log_seed_step Seeds::PopulateCaseflowFromVacols

    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end

