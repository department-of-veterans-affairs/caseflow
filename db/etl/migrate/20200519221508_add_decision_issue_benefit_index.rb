class AddDecisionIssueBenefitIndex < Caseflow::Migration
  def change
    add_safe_index :decision_issues, :benefit_type
  end
end
