class MakeAssignedToOnTaskPolymorphic < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :assigned_to_type, :string, null: false
  end
end
