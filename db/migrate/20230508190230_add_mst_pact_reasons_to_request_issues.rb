class AddMstPactReasonsToRequestIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues, :mst_status_update_reason_notes, :text, comment: "The reason for why Request Issue is Military Sexual Trauma (MST)"
    add_column :request_issues, :pact_status_update_reason_notes, :text, comment: "The reason for why Request Issue is Promise to Address Comprehensive Toxics (PACT) Act"
  end
end
