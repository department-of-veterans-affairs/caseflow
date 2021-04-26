# frozen_string_literal: true

class ValidateForeignKeysToTasksTable < Caseflow::Migration
  def change
    validate_foreign_key "task_timers", "tasks"
    validate_foreign_key "tasks", column: "parent_id"
    validate_foreign_key "hearing_task_associations", column: "hearing_task_id"

    validate_foreign_key "distributed_cases", "tasks"
    validate_foreign_key "distributed_cases", "distributions"
  end
end
