class CreateSpecialIssueChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :special_issue_changes do |t|
      t.bigint :issue_id, null: false, comment: "ID of the issue that was changed"
      t.bigint :appeal_id, null: false, comment: "AMA or Legacy Appeal ID that the issue is tied to"
      t.string :appeal_type, null: false, comment: "Appeal Type (Appeal or LegacyAppeal)"
      t.bigint :task_id, null: false, comment: "Task ID of the IssueUpdateTask or EstablishmentTask used to log this issue in the case timeline"
      t.datetime "created_at", null: false, comment: "Date the special issue change was made"
      t.bigint :created_by_id, null: false, comment: "User ID of the user that made the special issue change"
      t.string :created_by_css_id, null: false, comment: "CSS ID of the user that made the special issue change"
      t.boolean :original_mst_status, null: false, comment: "Original MST special issue status of the issue"
      t.boolean :original_pact_status, null: false, comment: "Original PACT special issue status of the issue"
      t.boolean :updated_mst_status, null: false, comment: "Updated MST special issue status of the issue"
      t.boolean :updated_pact_status, null: false, comment: "Updated PACT special issue status of the issue"
      t.boolean :mst_from_vbms, default: false, comment: "Indication that the MST status originally came from VBMS on intake"
      t.boolean :pact_from_vbms, default: false, commment: "Indication that the PACT status originally came from VBMS on intake"
      t.string :mst_reason_for_change, comment: "Reason for changing the MST status on an issue"
      t.string :pact_reason_for_change, comment: "Reason for changing the PACT status on an issue"
    end
  end
end
