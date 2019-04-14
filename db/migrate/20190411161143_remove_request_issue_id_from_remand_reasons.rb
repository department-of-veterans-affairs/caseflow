class RemoveRequestIssueIdFromRemandReasons < ActiveRecord::Migration[5.1]
  def change
  	safety_assured { remove_column :remand_reasons, :request_issue_id }
  end
end
