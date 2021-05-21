class AddForeignKeysForRequestIssues < Caseflow::Migration
  def change
    add_foreign_key "legacy_issue_optins", "request_issues", validate: false
    add_foreign_key "legacy_issues", "request_issues", validate: false
  end
end
