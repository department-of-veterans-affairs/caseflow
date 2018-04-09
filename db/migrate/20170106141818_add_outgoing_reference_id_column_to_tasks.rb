class AddOutgoingReferenceIdColumnToTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :outgoing_reference_id, :string
  end
end
