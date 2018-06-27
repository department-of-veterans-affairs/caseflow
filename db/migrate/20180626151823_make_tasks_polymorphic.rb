class MakeTasksPolymorphic < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :appeal_type, :string, null: false
  end
end
