# frozen_string_literal: true

class AddForeignKeysToUsersTable < Caseflow::Migration
  def change
    add_foreign_key "cavc_remands", "users", column: "created_by_id", validate: false
    add_foreign_key "cavc_remands", "users", column: "updated_by_id", validate: false
    add_foreign_key "virtual_hearings", "users", column: "created_by_id", validate: false

    add_foreign_key "tasks", "users", column: "assigned_by_id", validate: false
    add_foreign_key "tasks", "users", column: "cancelled_by_id", validate: false

    add_foreign_key "distributions", "users", column: "judge_id", validate: false
    add_foreign_key "hearings", "users", column: "judge_id", validate: false
    add_foreign_key "hearing_days", "users", column: "judge_id", validate: false
    add_foreign_key "sent_hearing_email_events", "users", column: "sent_by_id", validate: false

    add_foreign_key "judge_case_reviews", "users", column: "attorney_id", validate: false
    add_foreign_key "judge_case_reviews", "users", column: "judge_id", validate: false
  end
end
