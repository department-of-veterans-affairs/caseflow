# frozen_string_literal: true

class LegacyIssueOptinCreator
  def self.create_optin(request_issue:, vacols_issue:, legacy_issue:)
    LegacyIssueOptin.create!(
      request_issue: request_issue,
      original_disposition_code: vacols_issue.disposition_id,
      original_disposition_date: vacols_issue.disposition_date,
      legacy_issue: legacy_issue,
      original_legacy_appeal_decision_date: vacols_issue&.legacy_appeal&.decision_date,
      original_legacy_appeal_disposition_code: vacols_issue&.legacy_appeal&.case_record&.bfdc,
      folder_decision_date: vacols_issue&.legacy_appeal&.case_record&.folder&.tidcls
    )
  end
end
