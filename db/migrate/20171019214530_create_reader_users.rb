class CreateReaderUsers < ActiveRecord::Migration
  safety_assured # This is a new table. It'll be fine

  def change
    create_table :reader_users do |t|
      t.belongs_to :user, null: false
      t.datetime :current_appeals_documents_fetched_at
    end

    add_index(:reader_users, [:user_id], unique: true)
    add_index(:reader_users, [:current_appeals_documents_fetched_at])
  end
end
