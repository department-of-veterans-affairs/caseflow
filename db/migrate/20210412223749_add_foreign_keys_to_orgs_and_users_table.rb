# frozen_string_literal: true

class AddForeignKeysToOrgsAndUsersTable < Caseflow::Migration
  def change
    add_foreign_key "ihp_drafts", "organizations", validate: false
    add_foreign_key "organizations_users", "organizations", validate: false
    add_foreign_key "vso_configs", "organizations", validate: false

    add_foreign_key "job_notes", "users", validate: false
    add_foreign_key "messages", "users", validate: false
  end
end
