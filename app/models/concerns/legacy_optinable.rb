module LegacyOptinable
  extend ActiveSupport::Concern

  def create_legacy_issue_optin(request_issue)
    legacy_optin = LegacyIssueOptin.create!(request_issue: request_issue).tap(&:submit_for_processing!)
    if LegacyIssueOptin.run_async?
      LegacyOptinProcessJob.perform_later(legacy_optin)
    else
      LegacyOptinProcessJob.perform_now(legacy_optin)
    end
  end

  def vacols_optin_special_issue
    { code: "VO", narrative: "VACOLS Opt-in" }
  end

  def needs_vacols_optin_special_issue?
    request_issues.any?(&:vacols_id)
  end
end
