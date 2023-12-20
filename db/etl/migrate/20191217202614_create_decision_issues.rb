class CreateDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    create_table :decision_issues, comment: "Copy of decision_issues" do |t|
      t.bigint "decision_review_id", comment: "decision_issues.decision_review_id"
      t.string "decision_review_type", limit: 20, comment: "decision_issues.decision_review_type"
      t.string "decision_text", comment: "decision_issues.decision_text"
      t.date "caseflow_decision_date", comment: "decision_issues.caseflow_decision_date"
      t.string "disposition", limit: 50, comment: "decision_issues.disposition"
      t.string "description", comment: "decision_issues.description"
      t.string "benefit_type", limit: 20, comment: "decision_issues.benefit_type"
      t.bigint "participant_id", null: false, comment: "decision_issues.participant_id"
      t.bigint "rating_issue_reference_id", comment: "decision_issues.rating_issue_reference_id"
      t.datetime "rating_promulgation_date", comment: "decision_issues.rating_promulgation_date"
      t.datetime "rating_profile_date", comment: "decision_issues.rating_profile_date"
      t.date "end_product_last_action_date", comment: "decision_issues.end_product_last_action_date"
      t.string "diagnostic_code", limit: 20, comment: "decision_issues.diagnostic_code"
      t.datetime "issue_created_at", comment: "decision_issues.created_at"
      t.datetime "issue_updated_at", comment: "decision_issues.updated_at"
      t.datetime "issue_deleted_at", comment: "decision_issues.deleted_at"
      t.datetime "created_at", null: false, comment: "Default created_at/updated_at for the ETL record"
      t.datetime "updated_at", null: false, comment: "Default created_at/updated_at for the ETL record"

      t.index ["participant_id"]
      t.index ["disposition"]
      t.index ["created_at"]
      t.index ["updated_at"]
      t.index ["issue_created_at"]
      t.index ["issue_updated_at"]
      t.index ["issue_deleted_at"]
    end

    # easiest to customize name for length outside the create_table block
    add_index :decision_issues,
              ["decision_review_id", "decision_review_type"],
              name: "index_decision_issues_decision_review"
    add_index :decision_issues,
              ["rating_issue_reference_id", "disposition", "participant_id"],
              name: "index_decision_issues_uniq",
              unique: true
  end
end
