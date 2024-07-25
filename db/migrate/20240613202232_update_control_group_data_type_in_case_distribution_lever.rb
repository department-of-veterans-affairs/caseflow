class UpdateControlGroupDataTypeInCaseDistributionLever < ActiveRecord::Migration[6.0]
  def change
    safety_assured { remove_column :case_distribution_levers, :control_group, :json, comment: 'supports the exclusion table that has toggles that control multiple levers' }
    add_column :case_distribution_levers, :control_group, :string, comment: 'supports the exclusion table that has toggles that control multiple levers'
  end
end
