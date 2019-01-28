class CreateTaskTimers < ActiveRecord::Migration[5.1]
  def change
    create_table :task_timers do |t|
      t.belongs_to :task, null: false
      t.timestamps null: false
      t.datetime :submitted_at
      t.datetime :attempted_at
      t.datetime :processed_at
      t.string :error
    end
  end
end
