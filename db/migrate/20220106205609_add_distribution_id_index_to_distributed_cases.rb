class AddDistributionIdIndexToDistributedCases < Caseflow::Migration
  def change
    add_safe_index :distributed_cases, :distribution_id
  end
end
