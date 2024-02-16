class AddMstPactToDecisionIssues < Caseflow::Migration
  def change
    add_column :decision_issues, :mst_status, :boolean, default: false, comment: "Indicates if decision issue is related to Military Sexual Trauma (MST)"
    add_column :decision_issues, :pact_status, :boolean, default: false, comment: "Indicates if decision issue is related to Promise to Address Comprehensive Toxics (PACT) Act"
  end
end
