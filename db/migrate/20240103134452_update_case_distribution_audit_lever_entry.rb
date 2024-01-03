class UpdateCaseDistributionAuditLeverEntry < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :case_distribution_audit_lever_entries, :user_name, :string
      remove_column :case_distribution_audit_lever_entries, :title, :string
      change_column_null :case_distribution_audit_lever_entries, :user_id, false
    end
  end
end
