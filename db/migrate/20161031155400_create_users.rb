class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string   :station_id, null: false
      t.string   :css_id, null: false
    end
    add_index(:users, [:station_id, :css_id], unique: true)
  end
end
