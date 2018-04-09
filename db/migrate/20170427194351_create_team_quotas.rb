class CreateTeamQuotas < ActiveRecord::Migration[5.1]
  safety_assured # This is a new table. It'll be fine

  def change
    create_table :team_quotas do |t|
      t.date     :date, null: false
      t.string   :task_type, null: false
      t.integer  :user_count
 
      t.timestamps null: false
    end

    add_index(:team_quotas, [:date, :task_type], unique: true)
  end
end
