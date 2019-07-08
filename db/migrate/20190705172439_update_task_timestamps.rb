class UpdateTaskTimestamps < ActiveRecord::Migration[5.1]
  def change
    Task.find_each do |task|
      task.update!(closed_at: task.updated_at) if !task.open? && task.closed_at.nil?
      task.update!(started_at: task.updated_at) if task.status == "in_progress" && task.started_at.nil?
      task.update!(placed_on_hold_at: task.updated_at) if task.status == "on_hold" && task.placed_on_hold_at.nil?
    end
  end
end
