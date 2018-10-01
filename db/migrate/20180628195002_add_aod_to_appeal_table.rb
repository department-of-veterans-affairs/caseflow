class AddAodToAppealTable < ActiveRecord::Migration[5.1]
  safety_assured # This is a new table. Adding a default is fine.

  def change
    add_column :appeals, :advanced_on_docket, :boolean, default: false
  end
end
