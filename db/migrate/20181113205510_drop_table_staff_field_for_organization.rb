class DropTableStaffFieldForOrganization < ActiveRecord::Migration[5.1]
  def change
    drop_table :staff_field_for_organizations
  end
end
