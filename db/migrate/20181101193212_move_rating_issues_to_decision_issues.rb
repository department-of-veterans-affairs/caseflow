class MoveRatingIssuesToDecisionIssues < ActiveRecord::Migration[5.1]
  safety_assured

  def up
    rename_column :decision_issues, :request_issue_id, :source_request_issue_id
    change_column :decision_issues, :source_request_issue_id, :bigint, null: false
    add_column :decision_issues, :promulgation_date, :datetime
    add_column :decision_issues, :profile_date, :datetime
    add_column :decision_issues, :participant_id, :integer, null: false
    add_column :decision_issues, :rating_issue_reference_id, :string, null: false
    add_column :decision_issues, :decision_text, :string
    safety_assured do
      add_index(:decision_issues, [:rating_issue_reference_id, :participant_id], unique: true, name: "decision_issues_uniq_idx")
      add_index(:decision_issues, :source_request_issue_id)
    end
  end

  def down
    remove_index :decision_issues, [:rating_issue_reference_id, :participant_id]
    remove_index :decision_issues, :source_request_issue_id
    change_column :decision_issues, :source_request_issue_id, :integer, null: true
    rename_column :decision_issues, :source_request_issue_id, :request_issue_id
    remove_column :decision_issues, :promulgation_date
    remove_column :decision_issues, :profile_date
    remove_column :decision_issues, :participant_id
    remove_column :decision_issues, :rating_issue_reference_id
    remove_column :decision_issues, :decision_text
  end
end
