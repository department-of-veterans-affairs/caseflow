class AddDecisionDateToRequestIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :decision_date, :date
  end
end
