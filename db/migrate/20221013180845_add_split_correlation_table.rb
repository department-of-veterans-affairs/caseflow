class AddSplitCorrelationTable < Caseflow::Migration
  def change
    create_table "split_correlation_tables", comment: "Associates the request issues of the split appeal to the original appeal." do |t|
      t.integer "appeal_id", comment: "The new ID of the split appeal associated with this record."
      t.integer  "original_appeal_id", null: false, comment: "The original appeal id from where the split appeal appeal_id was created from."
      t.string "relationship_type", default: "split_appeal", comment: "The new split_appeal relationship type created from the split and maybe used for future correlations."
      t.uuid "appeal_uuid", default: -> { "uuid_generate_v4()" }, null: false, comment: "The universally unique identifier for the appeal, which allows a single ID to determine an appeal for Caseflow splitted appeals."
      t.string "original_appeal_uuid", null: false, comment: "The original source appeal uuid from where the split was generated from."
      t.string "appeal_type", null: false, comment: "The type of appeal that the split appeal was orginally motioned as (i.e. DR,ES,SC)."
      t.integer  "created_by_id", null: false, comment: "The user css_id that created the split appeal."
      t.datetime "created_at", null: false, comment: "The datetime when the split appeal was created"
      t.integer  "updated_by_id", comment: "The user css_id who most recently updated the split appeal workflow."
      t.datetime "updated_at", comment: "The datetime when the split appeal was updated at."
      t.string "working_split_status", null: false, default: "in_progress", comment: "The work flow status of the split appeal (i.e. on_hold, in_progress, cancelled, completed)."
      t.string "split_reason", comment: "Reason for splitting the appeal from drop menu."
      t.string "split_other_reason", comment: "The other reason for splitting the appeal from comment section."
      t.integer "split_request_issue_ids", null: false, comment: "An array of the split request issue IDs that were transferred to the split appeal.", array: true
      t.integer "original_request_issue_ids", null: false, comment: "An array of the original request issue IDs that were transferred to the split appeal.", array: true
    end
  
    add_foreign_key "split_correlation_tables", "users", column: "created_by_id", validate: false
    add_foreign_key "split_correlation_tables", "users", column: "updated_by_id", validate: false
  end
end
    