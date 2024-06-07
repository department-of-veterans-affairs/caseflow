class CreateIssueModificationRequest < ActiveRecord::Migration[6.0]
  def change
    create_table :issue_modification_requests, comment: "A database table to store issue modification requests for a decision review for altering or adding additional request_issues" do |t|
      t.references :request_issue, foreign_key: true, null: true, comment: "Specifies the request issue targeted by the modification request."
      t.references :decision_review, polymorphic: true, null: true, index: {name: :index_issue_modification_requests_decision_review}, comment: "The decision review that this issue modification request belongs to"
      t.string "request_type", default: "addition", comment:  "The type of issue modification request. The possible types are addition, modification, withdrawal and cancelled."
      t.text "request_reason", null: true, comment: "The reason behind the modification request provided by the user initiating it."
      t.string "benefit_type", null: true, comment: "This will primarily apply when the request type is an addition, indicating the benefit type of the issue that will be created if the modification request is approved."
      t.date "decision_date", null: true, comment: "The decision date of the request issue that is being modified"
      t.text "decision_reason", null: true, comment: "The reason behind the approve/denial of the modification request provided by the user (admin) that is acting on the request."
      t.string "nonrating_issue_category", null: true, comment: "The nonrating issue category of the request issue that is being modified or added by the request"
      t.string "nonrating_issue_description", null: true, comment: "The nonrating issue description of the request issue that is being modified or added by the request"
      t.datetime "withdrawal_date", null: true, comment: "The withdrawal date for issue modification requests with a request type of withdrawal"
      t.string "status", default: "assigned", comment: "The status of the issue modifications request. The possible status values are assigned, approved, denied, and cancelled"
      t.datetime "decided_at", null: true, comment: "Timestamp when the decision was made by the decider/admin. it can be approved or denied date."
      t.datetime "edited_at", null: true, comment: "Timestamp when the requestor or decider edits the issue modification request."
      t.boolean "remove_original_issue", default: false, comment: "flag to indicate if the original issue was removed or not."
      t.references :requestor, index: true, foreign_key: { to_table: :users }, comment: "The user who requests modification or addition of request issues"
      t.references :decider, index: true, foreign_key: { to_table: :users }, comment: "The user who decides approval/denial of the issue modification request."
      t.timestamps
    end
  end
end
