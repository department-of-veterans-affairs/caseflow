class AddOutgoingReferenceIdColumnToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :outgoing_reference_id, :string
  end
end
