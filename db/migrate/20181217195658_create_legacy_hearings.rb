class CreateLegacyHearings < ActiveRecord::Migration[5.1]
  def change
    create_table :legacy_hearings do |t|
      t.integer :user_id
      t.integer :appeal_id
      t.string  :vacols_id, null: false
      t.string  :witness
      t.string  :military_service
      t.boolean :prepped
      t.text    :summary
    end
  end
end
