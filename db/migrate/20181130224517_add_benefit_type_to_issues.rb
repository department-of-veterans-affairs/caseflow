class AddBenefitTypeToIssues < ActiveRecord::Migration[5.1]
  def change
    add_column :request_issues, :benefit_type, :string
    add_column :decision_issues, :benefit_type, :string
  end
end
