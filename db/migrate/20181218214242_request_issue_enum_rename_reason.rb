class RequestIssueEnumRenameReason < ActiveRecord::Migration[5.1]
  def up
    execute "UPDATE request_issues SET ineligible_reason='duplicate_of_rating_issue_in_active_review' WHERE ineligible_reason='duplicate_of_issue_in_active_review'"
  end

  def down
    execute "UPDATE request_issues SET ineligible_reason='duplicate_of_issue_in_active_review' WHERE ineligible_reason='duplicate_of_rating_issue_in_active_review'"
  end
end
