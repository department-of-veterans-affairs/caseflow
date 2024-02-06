class AddVbmsMstAndPactToRequestIssues < ActiveRecord::Migration[5.2]
  def change
    add_column :request_issues, :vbms_mst_status, :boolean, default: false, comment: "Indicates if issue is related to Military Sexual Trauma (MST) and was imported from VBMS"
    add_column :request_issues, :vbms_pact_status, :boolean, default: false ,comment: "Indicates if issue is related to Promise to Address Comprehensive Toxics (PACT) Act and was imported from VBMS"
  end
end
