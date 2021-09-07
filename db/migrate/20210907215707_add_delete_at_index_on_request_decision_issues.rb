class AddDeleteAtIndexOnRequestDecisionIssues < Caseflow::Migration
  def change
    # Use a partial index since we don't need to query by a non-null deleted_at value.
    # https://www.johnnunemaker.com/rails-postgres-partial-indexing/
    # A partial index should be cheaper: https://dba.stackexchange.com/a/102513
    add_safe_index(:request_decision_issues, :deleted_at, where: "deleted_at IS NULL", algorithm: :concurrently)
  end
end
