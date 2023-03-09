class UpdateBusinessLineTasksToVersion2 < ActiveRecord::Migration[5.2]
  def change
    create_view :business_line_tasks, materialized: true
  end
end
