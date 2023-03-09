class RemoveMaterializedViewBusinessLineTasks < ActiveRecord::Migration[5.2]
  def change
    drop_view :business_line_tasks, materialized: 1
  end
end
