class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string    :vacols_id, null: false
      t.string    :name, null: false
      # TODO ask shane about this format
      t.integer   :employee_id
      t.datetime  :assigned_at
      t.datetime  :started_at
      t.datetime  :completed_at
      # status value is only saved when task is complete
      t.integer   :status

      t.timestamps null: false
    end

    # TODO research if we need any indexes for improving work queue select queries
    add_index(:tasks, [:vacols_id, :name], unique: true)
  end
end
