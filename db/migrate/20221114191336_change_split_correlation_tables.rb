class ChangeSplitCorrelationTables < ActiveRecord::Migration[5.2]
  def up
    change_table "split_correlation_tables" do |t|
      t.integer :split_request_issue_id, :original_request_issue_id, null: false, comment: "The original request issue id and the corresponding request issue id created from the split appeal process."
    end
    safety_assured { remove_column :split_correlation_tables, :split_request_issue_ids }
    safety_assured { remove_column :split_correlation_tables, :original_request_issue_ids }
  end
  def down
    change_table "split_correlation_tables" do |t|
      t.integer "split_request_issue_ids", null: false, comment: "An array of the split request issue IDs that were transferred to the split appeal.", array: true
      t.integer "original_request_issue_ids", null: false, comment: "An array of the original request issue IDs that were transferred to the split appeal.", array: true
    end
    safety_assured { remove_column :split_correlation_tables, :split_request_issue_id }
    safety_assured { remove_column :split_correlation_tables, :original_request_issue_id }
  end
end
