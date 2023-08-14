class UpdateSpecialIssueChanges < ActiveRecord::Migration[5.2]
  def up
    safety_assured do
      change_column :special_issue_changes, :updated_mst_status, :boolean, null: true, default: nil
      change_column :special_issue_changes, :updated_pact_status, :boolean, null: true, default: nil
      change_column :special_issue_changes, :mst_from_vbms, :boolean, null: true, default: nil
      change_column :special_issue_changes, :pact_from_vbms, :boolean, null: true, default: nil
    end
  end

  def down
    safety_assured do
      change_column :special_issue_changes, :updated_mst_status, :boolean, null: false
      change_column :special_issue_changes, :updated_pact_status, :boolean, null: false
      change_column :special_issue_changes, :mst_from_vbms, :boolean, null: false
      change_column :special_issue_changes, :pact_from_vbms, :boolean, null: false
    end
  end
end
