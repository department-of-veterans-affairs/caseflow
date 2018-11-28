module LegacyOptinable
  extend ActiveSupport::Concern

  def create_legacy_issue_optin(request_issue)
    legacy_optin = LegacyIssueOptin.create!(request_issue: request_issue)
    if run_async?
      LegacyOptinProcessJob.perform_later(legacy_optin)
    else
      LegacyOptinProcessJob.perform_now(legacy_optin)
    end
  end
end
