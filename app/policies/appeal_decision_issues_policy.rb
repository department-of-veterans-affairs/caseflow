class AppealDecisionIssuesPolicy
  def initialize(user:, appeal:)
    @user = user
    @appeal = appeal
  end

  def visible_decision_issues
    if @user.roles.include?("VSO")
      @appeal.decision_issues.select { |issue| Time.now.utc > issue.caseflow_decision_date }
    else
      @appeal.decision_issues
    end
  end
end
