class DropVacolsIdFromLegacyIssueOptin < ActiveRecord::Migration[5.1]
  def change
    remove_column :legacy_issue_optins, :vacols_id, :string
    remove_column :legacy_issue_optins, :vacols_sequence_id, :integer
  end
end
