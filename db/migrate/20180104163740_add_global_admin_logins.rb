class AddGlobalAdminLogins < ActiveRecord::Migration
  def change
    create_table :global_admin_logins do |t|
      t.string :admin_css_id
      t.string :target_css_id
      t.string :target_station_id
      t.timestamps
    end
  end
end
