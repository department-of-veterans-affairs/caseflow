class AddCreatedAtAndUpdatedAtColumnsToBatchProcesses < Caseflow::Migration
  def change
    add_column :batch_processes, :created_at, :datetime, null: false, comment: "Date and Time that batch was created."
    add_column :batch_processes, :updated_at, :datetime, null: false, comment: "Date and Time that batch was last updated."
  end
end
