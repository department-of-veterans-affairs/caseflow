class ChangeDecisionIssuesUniqueIndex < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
	  remove_index :intakes, name: 'decision_issues_uniq_idx'

	  add_index(
	  	:decision_issues,
	  	[:rating_issue_reference_id, :disposition, :participant_id],
	  	unique: true,
	  	name: "decision_issues_uniq_by_disposition_and_ref_id",
	  	algorithm: :concurrently
	  )
  end

  def down
    remove_index :intakes, name: 'decision_issues_uniq_by_disposition_and_ref_id'
    add_index(:decision_issues, [:rating_issue_reference_id, :participant_id], unique: true, name: "decision_issues_uniq_idx")
  end
end
