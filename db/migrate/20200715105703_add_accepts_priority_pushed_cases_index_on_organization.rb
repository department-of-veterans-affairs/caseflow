class AddAcceptsPriorityPushedCasesIndexOnOrganization < Caseflow::Migration
  def change
    add_safe_index :organizations, :accepts_priority_pushed_cases
  end
end
