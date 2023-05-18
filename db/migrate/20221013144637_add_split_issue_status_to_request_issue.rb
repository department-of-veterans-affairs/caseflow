class AddSplitIssueStatusToRequestIssue < Caseflow::Migration
  def change
    add_column :request_issues, :split_issue_status, :string, comment: "If a request issue is part of a split, on_hold status applies to the original request issues while active are request issues on splitted appeals"
  end
end
