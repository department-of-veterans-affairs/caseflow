class CreateIssueModificationRequest < ActiveRecord::Migration[6.0]
  def change
    create_table :issue_modification_requests, comment: "A database table to store pending request issues that are for modification" do |t|
      t.references :request_issue, foreign_key: true, null: true, comment:"Indicates the id of the request_issues on which the modification was requested."
      t.references :decision_review, polymorphic: true, null: true, index: {name: :index_issue_modification_requests_decision_review}, comment: "Mostly used when request type is addition"
      t.string "request_type", default: "Addition", limit: 20, comment:  "Issue modification request type can be addition, modification, withdrawal and cancelled."
      t.text "request_reason", null: true, comment: "Requestor enters Issue modification request reason for why new issue is being request or modified or withdrawn."
      t.string "benefit_type", null: true, comment: "This will be mostly be used when request type is addition. it reflects what benefit type the issue belongs to."
      t.datetime "decision_date", null: true, comment: "prior decision Date of the issue if any"
      t.text "decided_decision_text", null: true, comment: "Decider (admin user) adds Description during approval/denial"
      t.string "nonrating_issue_category", null: true, comment: "issue category decision_issues.non_rating_issue_category"
      t.datetime "withdrawal_date", null: true, comment: "if request issue was withdrawn then we save it as withdrawal date "
      t.string "status", default: "assigned", comment: "status of the pending task"
      t.datetime "decided_at", null: true, comment: "Timestamp when the decision was made by the decider/admin. it can be approved or denied date."
      t.boolean "remove_original_issue", default: false, comment: "flag to indicate if the original issue was removed or not."
      t.references :requestor, index: true, foreign_key: { to_table: :users }, comment: "The user who requests modification or addition of request issues"
      t.references :decider, index: true, foreign_key: { to_table: :users }, comment: "The user who decides approval/denial of requested issues"
      t.timestamps
    end
  end
end
