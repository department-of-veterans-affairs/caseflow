class AddHomelessnessToAppeals < ActiveRecord::Migration[5.2]
  def change
    add_column :appeals, :homelessness, :boolean, :default=>false, null: false, comment: "Indicates whether or not a veteran is experiencing homelessness"
  end
end
