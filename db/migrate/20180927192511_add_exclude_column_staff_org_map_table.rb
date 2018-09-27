class AddExcludeColumnStaffOrgMapTable < ActiveRecord::Migration[5.1]
  def change
    safety_assured { add_column :staff_field_for_organizations, :exclude, :boolean, default: false }
  end
end
