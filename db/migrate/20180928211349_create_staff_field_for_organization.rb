class CreateStaffFieldForOrganization < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    create_table :staff_field_for_organizations do |t|
      t.belongs_to :organization, null: false
      t.string :name, null: false
      t.string :values, default: [], array: true, null: false
      t.boolean :exclude, default: false
    end
  end
end
