class CreateVsoConfigs < ActiveRecord::Migration[5.1]
  def change
    create_table :vso_configs do |t|
      t.column :organization_id, :integer
      t.column :ihp_dockets, :string, array: true
      t.index :organization_id

      t.timestamps
    end
  end
end
