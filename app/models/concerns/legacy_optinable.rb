module LegacyOptinable
  extend ActiveSupport::Concern

  private

  def create_legacy_issue_optin(request_issue:, action:)
    legacy_optin = LegacyIssueOptin.create!(
      request_issue: request_issue,
      action: action,
      vacols_id: request_issue.vacols_id,
      vacols_sequence_id: request_issue.vacols_sequence_id
    ).tap(&:submit_for_processing!)
    if LegacyIssueOptin.run_async?
      LegacyOptinProcessJob.perform_later(legacy_optin)
    else
      LegacyOptinProcessJob.perform_now(legacy_optin)
    end
  end

  def vacols_optin_special_issue
    { code: "VO", narrative: Constants.VACOLS_DISPOSITIONS_BY_ID.O }
  end

  def needs_vacols_optin_special_issue?
    request_issues.any?(&:legacy_issue_opted_in?)
  end
end
