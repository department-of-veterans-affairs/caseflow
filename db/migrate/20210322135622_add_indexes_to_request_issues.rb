class AddIndexesToRequestIssues < Caseflow::Migration
  def change
    add_safe_index :request_issues, [:veteran_participant_id], name: :index_veteran_participant_id
  end
end
