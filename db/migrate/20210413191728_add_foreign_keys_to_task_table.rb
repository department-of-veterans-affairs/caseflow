# frozen_string_literal: true

class AddForeignKeysToTaskTable < Caseflow::Migration
  def change
    add_foreign_key "task_timers", "tasks", validate: false
    add_foreign_key "tasks", "tasks", column: "parent_id", validate: false
    add_foreign_key "hearing_task_associations", "tasks", column: "hearing_task_id", validate: false

    add_foreign_key "distributed_cases", "tasks", validate: false
    add_foreign_key "distributed_cases", "distributions", validate: false
  end
end
