class CreateAppealView < ActiveRecord::Migration[5.1]
  # This is a new table, so the new indices will be fine
  safety_assured
  
  def change
    create_table :appeal_views do |t|
      t.belongs_to :user, null: false
      t.belongs_to :appeal, null: false

      t.timestamps null: false
      t.datetime   :last_viewed_at
    end

    add_index(:appeal_views, [:appeal_id, :user_id], unique: true)
  end
end
