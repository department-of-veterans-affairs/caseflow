class AddPactActToSpecialIssueLists < Caseflow::Migration
  def up
    add_column :special_issue_lists, :pact_act, :boolean, default: false, comment: "The Sergeant First Class (SFC) Heath Robinson Honoring our Promise to Address Comprehensive Toxics (PACT) Act"
  end

  def down
    remove_column :special_issue_lists, :pact_act
  end
end
