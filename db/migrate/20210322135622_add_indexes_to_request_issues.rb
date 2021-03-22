class AddIndexesToRequestIssues < Caseflow::Migration
  def change
    add_safe_index :request_issues, [:nonrating_issue_category], name: :index_nonrating_issue_category
    add_safe_index :request_issues, [:veteran_participant_id], name: :index_veteran_participant_id
  end
end
