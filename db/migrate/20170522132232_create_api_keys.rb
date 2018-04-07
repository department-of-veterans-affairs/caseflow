class CreateApiKeys < ActiveRecord::Migration[5.1]
  # This is a new table, so the new indecies will be fine
  safety_assured

  def change
    create_table :api_keys do |t|
      t.string :consumer_name, null: false
      t.string :key_digest, null: false
    end

    add_index(:api_keys, :key_digest, unique: true)
    add_index(:api_keys, :consumer_name, unique: true)
  end
end
