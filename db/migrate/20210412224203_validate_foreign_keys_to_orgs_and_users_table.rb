# frozen_string_literal: true

class ValidateForeignKeysToOrgsAndUsersTable < Caseflow::Migration
  def change
    validate_foreign_key "ihp_drafts", "organizations"
    validate_foreign_key "organizations_users", "organizations"
    validate_foreign_key "vso_configs", "organizations"

    validate_foreign_key "job_notes", "users"
    validate_foreign_key "messages", "users"
  end
end
