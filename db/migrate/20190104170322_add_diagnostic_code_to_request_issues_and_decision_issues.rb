class AddDiagnosticCodeToRequestIssuesAndDecisionIssues < ActiveRecord::Migration[5.1]
  def change
  	add_column :request_issues, :diagnostic_code, :string
  	add_column :decision_issues, :diagnostic_code, :string
  end
end
