class AddIndexToPriorityQueueNumber < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def up
    add_safe_index :national_hearing_queue_entries, :priority_queue_number
  end

  def down
    remove_index :national_hearing_queue_entries, column: :priority_queue_number, algorithm: :concurrently
  end
end
