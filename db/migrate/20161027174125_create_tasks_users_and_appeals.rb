class CreateTasksUsersAndAppeals < ActiveRecord::Migration
  def change
    create_table :appeals do |t|
      t.string    :vacols_id, null: false
      t.string    :vbms_id
    end
    add_index(:appeals, :vacols_id, unique: true)

    create_table :users do |t|
      t.string   :station_id, null: false
      t.string   :css_id, null: false
    end
    add_index(:users, [:station_id, :css_id], unique: true)


    create_table :tasks do |t|
      t.integer    :appeal_id, null: false
      t.string    :name, null: false
      # TODO ask shane about this format
      t.integer   :user_id
      t.datetime  :assigned_at
      t.datetime  :started_at
      t.datetime  :completed_at
      # status value is only saved when task is complete
      t.integer   :status

      t.timestamps null: false
    end

    # TODO research if we need any indexes for improving work queue select queries
    add_index(:tasks, [:appeal_id, :name], unique: true)

    # Foreign keys
    add_foreign_key :tasks, :users
    add_foreign_key :tasks, :appeals
  end
end
