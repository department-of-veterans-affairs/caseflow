class CreateTeamQuotas < ActiveRecord::Migration
  safety_assured # This is a new table. It'll be fine

  def change
    create_table :team_quotas do |t|
      t.date     :date
      t.string   :task_type
      t.integer  :user_count
 
      t.timestamps null: false
    end

    add_index(:team_quotas, [:date, :task_type], unique: true)
  end
end
