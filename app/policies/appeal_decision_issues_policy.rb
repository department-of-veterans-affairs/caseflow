# frozen_string_literal: true

class AppealDecisionIssuesPolicy
  def initialize(user:, appeal:)
    @user = user
    @appeal = appeal
  end

  def visible_decision_issues
    if @user.roles.include?("VSO")
      visible_issues = @appeal.decision_issues.select do |issue|
        Time.now.utc > issue.caseflow_decision_date
      end
      modified_issues = visible_issues.map do |issue|
        issue.description = nil
        issue
      end
      modified_issues
    else
      @appeal.decision_issues
    end
  end
end
