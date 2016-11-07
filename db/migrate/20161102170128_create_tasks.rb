class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.belongs_to :appeal, null: false
      t.string     :type, null: false
      # TODO ask shane about this format
      t.belongs_to :user
      t.datetime   :assigned_at
      t.datetime   :started_at
      t.datetime   :completed_at
      t.integer    :completion_status

      t.timestamps null: false
    end

    # TODO research if we need any indexes for improving work queue select queries
    add_index(:tasks, [:appeal_id, :type], unique: true)

  end
end
