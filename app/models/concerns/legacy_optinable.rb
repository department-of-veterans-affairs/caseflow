module LegacyOptinable
  extend ActiveSupport::Concern

  private

  def create_legacy_issue_optin(request_issue)
    LegacyIssueOptin.create!(request_issue: request_issue)
  end

  def vacols_optin_special_issue
    { code: "VO", narrative: Constants.VACOLS_DISPOSITIONS_BY_ID.O }
  end

  def needs_vacols_optin_special_issue?
    !!request_issues.legacy_issue_optin
  end
end
