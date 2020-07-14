class AddAutomatedPriorityCaseDistributionIndexOnOrganization < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :organizations, :automated_priority_case_distribution, algorithm: :concurrently
  end
end
