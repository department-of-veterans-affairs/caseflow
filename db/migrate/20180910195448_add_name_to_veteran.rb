class AddNameToVeteran < ActiveRecord::Migration[5.1]
  def change
    add_column :veterans, :first_name, :string
    add_column :veterans, :last_name, :string
    add_column :veterans, :middle_name, :string
    add_column :veterans, :name_suffix, :string
  end
end
