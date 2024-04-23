class PendingRequestIssue < Caseflow::Migration
  def change
    create_table :pending_request_issues, comment: "A database table to store pending request issues that are for modification" do |t|
      t.references :request_issue, foreign_key: true, null: true, comment:"Indicates the id of the request_issues on which the modification was requested"
      t.bigint "decision_review_id", comment: "decision_issues.decision_review_id"
      t.string "decision_review_type", limit: 20, comment: "decision_issues.decision_review_type"
      t.string "request_type", limit: 20, comment:  "Pending Request Type"
      t.datetime "request_date", comment: "Requested Date"
      t.text "request_reason", comment: "request reason"
      t.string "benefit_type", limit: 20, comment: "decision_issues.benefit_type"
      t.string "nonrating_issue_category", null: true, comment: "issue category decision_issues.non_rating_issue_category"
      t.datetime "withdrawal_date", null: true, comment: "if request issue was withdrawn then we save it as withdrawal date "
      t.boolean "approved_status", comment: "withdraw status"
      t.datetime "approved_at", comment: "Timestamp when the request issue was closed. The reason it was closed is in closed_status."
      t.boolean "remove_original_issue", comment: "flag to indicate if the original issue was removed or not."
      t.references :created_by , index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
