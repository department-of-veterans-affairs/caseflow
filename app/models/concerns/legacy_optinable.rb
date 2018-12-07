module LegacyOptinable
  extend ActiveSupport::Concern

  private

  def create_legacy_issue_optin(request_issue:, action:)
    # check that the optin is complete before starting the rollback?
    legacy_optin = LegacyIssueOptin.create!(request_issue: request_issue, action: action).tap(&:submit_for_processing!)
    if LegacyIssueOptin.run_async?
      LegacyOptinProcessJob.perform_later(legacy_optin)
    else
      LegacyOptinProcessJob.perform_now(legacy_optin)
    end
  end

  def vacols_optin_special_issue
    { code: "VO", narrative: "AMA SOC/SSOC Opt-in" }
  end

  def needs_vacols_optin_special_issue?
    request_issues.any?(&:legacy_issue_opted_in?)
  end
end
