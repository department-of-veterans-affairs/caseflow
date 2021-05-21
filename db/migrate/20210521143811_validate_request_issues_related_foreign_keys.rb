class ValidateRequestIssuesRelatedForeignKeys < Caseflow::Migration
  def change
    validate_foreign_key "legacy_issue_optins", "request_issues"
    validate_foreign_key "legacy_issues", "request_issues"
  end
end
