class UsersUniqueCssId < ActiveRecord::Migration[5.1]
  def up
    safety_assured { execute "create unique index index_users_unique_css_id on users using btree (upper(css_id))" }
    remove_index(:users, [:station_id, :css_id])
  end

  def down
    safety_assured { execute "drop index index_users_unique_css_id" }
    add_index(:users, [:station_id, :css_id], unique: true, algorithm: :concurrently)
  end
end
