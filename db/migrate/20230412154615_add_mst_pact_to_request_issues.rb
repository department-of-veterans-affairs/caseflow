class AddMstPactToRequestIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues, :mst_status, :boolean, comment: "Indicates if issue is related to Military Sexual Trauam (MST)"
    add_column :request_issues, :pact_status, :boolean, comment: "Indicates if issue is related to Promise to Address Comprehensive Toxics (PACT) Act"
  end
end
