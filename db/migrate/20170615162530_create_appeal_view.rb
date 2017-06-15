class CreateAppealView < ActiveRecord::Migration
  # This is a new table, so the new indecies will be fine
  safety_assured
  
  def change
    create_table :appeal_views do |t|
      t.belongs_to :user, null: false
      t.belongs_to :appeal, null: false

      t.datetime   :first_viewed_at
      t.datetime   :last_viewed_at
    end

    add_index(:appeal_views, [:appeal_id, :user_id], unique: true)
  end
end
