class CreateIssueModificationRequest < ActiveRecord::Migration[6.0]
  def change
    create_table :issue_modification_requests, comment: "A database table to store pending request issues that are for modification" do |t|
      t.references :request_issue, foreign_key: true, null: true, comment:"Indicates the id of the request_issues on which the modification was requested"
      t.references :decision_review, polymorphic: true, null: true, index: {name: :index_issue_modification_requests_decision_review}
      t.string "request_type", limit: 20, comment:  "Pending Request Type"
      t.datetime "request_date", null: true, comment: "Requested Date"
      t.text "request_reason", null: true, comment: "request reason"
      t.string "benefit_type", limit: 20, null: true, comment: "decision_issues.benefit_type"
      t.datetime "decision_date", null: true, comment: "prior decision Date"
      t.text "decision_text", null: true, comment: "Description"
      t.string "nonrating_issue_category", null: true, comment: "issue category decision_issues.non_rating_issue_category"
      t.datetime "withdrawal_date", null: true, comment: "if request issue was withdrawn then we save it as withdrawal date "
      t.string "status", default: "assigned",null: true, comment: "status of the pending task"
      t.datetime "approved_at", null: true, comment: "Timestamp when the request issue was closed. The reason it was closed is in closed_status."
      t.boolean "remove_original_issue", default: false, comment: "flag to indicate if the original issue was removed or not."
      t.references :created_by, index: true, foreign_key: { to_table: :users }
      t.references :updated_by, index: true, foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
