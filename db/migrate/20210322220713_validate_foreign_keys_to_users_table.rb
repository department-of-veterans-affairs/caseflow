# frozen_string_literal: true

class ValidateForeignKeysToUsersTable < Caseflow::Migration
  def change
    validate_foreign_key "cavc_remands", column: "created_by_id"
    validate_foreign_key "cavc_remands", column: "updated_by_id"
    validate_foreign_key "virtual_hearings", column: "created_by_id"

    validate_foreign_key "tasks", column: "assigned_by_id"
    validate_foreign_key "tasks", column: "cancelled_by_id"

    validate_foreign_key "distributions", column: "judge_id"
    validate_foreign_key "hearings", column: "judge_id"
    validate_foreign_key "hearing_days", column: "judge_id"
    validate_foreign_key "sent_hearing_email_events", column: "sent_by_id"

    validate_foreign_key "judge_case_reviews", column: "attorney_id"
    validate_foreign_key "judge_case_reviews", column: "judge_id"
  end
end
