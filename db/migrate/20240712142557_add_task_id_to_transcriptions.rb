class AddTaskIdToTranscriptions < ActiveRecord::Migration[6.0]
  def up
    add_column :transcriptions, :task_id, :bigint
  end

  def down
    remove_column :transcriptions, :task_id
  end
end
