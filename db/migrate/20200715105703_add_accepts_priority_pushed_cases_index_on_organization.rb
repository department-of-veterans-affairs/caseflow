class AddAcceptsPriorityPushedCasesIndexOnOrganization < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :organizations, :accepts_priority_pushed_cases, algorithm: :concurrently
  end
end
