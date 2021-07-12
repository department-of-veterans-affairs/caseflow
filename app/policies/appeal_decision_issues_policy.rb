# frozen_string_literal: true

class AppealDecisionIssuesPolicy
  def initialize(user:, appeal:)
    @user = user
    @appeal = appeal
  end

  def visible_decision_issues
    if FeatureToggle.enabled?(:restrict_poa_visibility, user: @user)
      if @user.vso_employee?
        visible_issues = @appeal.decision_issues.select do |issue|
          # VSO users should not be able to see decision issues until the issue decision date
          Time.now.utc > issue.caseflow_decision_date
        end
        modified_issues = visible_issues.map do |issue|
          # VSO users should not be able to see decision issues' descriptions, regardless of the issue decision date
          issue.description = nil
          issue
        end
        modified_issues
      else
        @appeal.decision_issues
      end
    else
      @appeal.decision_issues
    end
  end
end
