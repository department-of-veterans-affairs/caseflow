class AddPactActToSpecialIssueLists < Caseflow::Migration
  def change
    add_column :special_issue_lists, :pact_act, :boolean, default: false, comment: "The Sergeant First Class (SFC) Heath Robinson Honoring our Promise to Address Comprehensive Toxics (PACT) Act"
  end
end
