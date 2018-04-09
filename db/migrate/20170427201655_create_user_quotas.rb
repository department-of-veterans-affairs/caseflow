class CreateUserQuotas < ActiveRecord::Migration[5.1]
  safety_assured # This is a new table. It'll be fine

  def change
    create_table :user_quotas do |t|
      t.belongs_to :team_quota, null: false
      t.belongs_to :user, null: false

      t.timestamps null: false
    end

    add_index(:user_quotas, [:team_quota_id, :user_id], unique: true)
  end
end
