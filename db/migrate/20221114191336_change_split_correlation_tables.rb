class ChangeSplitCorrelationTables < ActiveRecord::Migration[5.2]
  def change
    add_column :split_correlation_tables, :split_request_issue_id, :integer, null: false, comment: "The original request issue id and the corresponding request issue id created from the split appeal process."
    add_column :split_correlation_tables, :original_request_issue_id, :integer, null: false, comment: "The original request issue id and the corresponding request issue id created from the split appeal process."
    safety_assured { remove_column :split_correlation_tables, :split_request_issue_ids, :integer }
    safety_assured { remove_column :split_correlation_tables, :original_request_issue_ids, :integer }
  end
end
