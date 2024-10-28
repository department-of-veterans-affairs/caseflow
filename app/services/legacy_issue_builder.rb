class LegacyIssueBuilder
  def initialize(request_issue)
    @request_issue = request_issue
  end

  def create_legacy_issue
    LegacyIssue.create!(
      request_issue_id: @request_issue.id,
      vacols_id: @request_issue.vacols_id,
      vacols_sequence_id: @request_issue.vacols_sequence_id
    )
  end
end
