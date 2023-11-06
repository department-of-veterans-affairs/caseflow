class RemoveIdFromCaseDistributionLevers < ActiveRecord::Migration[5.2]
  def change

    remove_column :case_distribution_levers, :id
  end
end
