class AddLastActionDateToDecisionIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :decision_issues, :end_product_last_action_date, :date
    remove_column :decision_issues, :disposition_date, :string
  end
end
