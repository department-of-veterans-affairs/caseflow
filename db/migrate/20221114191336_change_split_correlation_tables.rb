class ChangeSplitCorrelationTables < ActiveRecord::Migration[5.2]
  def change
    change_table "split_correlation_tables" do |t|
      t.integer :split_request_issue_id, :original_request_issue_id, null: false, comment: "The original request issue id and the corresponding request issue id created from the split appeal process."
      safety_assured { t.remove :split_request_issue_ids, :original_request_issue_ids }
    end
  end
end
