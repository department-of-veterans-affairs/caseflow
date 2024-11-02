class AddUniqueIndexOnTaskIdToNhq < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def up
    add_safe_index :national_hearing_queue_entries, :task_id, unique: true
  end

  def down
    remove_index :national_hearing_queue_entries, :task_id, algorithm: concurrently
  end
end
