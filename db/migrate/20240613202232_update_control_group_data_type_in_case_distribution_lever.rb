class UpdateControlGroupDataTypeInCaseDistributionLever < ActiveRecord::Migration[6.0]
  def change
    safety_assured { remove_column :case_distribution_levers, :control_group }
    add_column :case_distribution_levers, :control_group, :string
  end
end
