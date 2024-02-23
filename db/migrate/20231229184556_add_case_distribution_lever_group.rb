class AddCaseDistributionLeverGroup < ActiveRecord::Migration[5.2]
  def change
    add_column :case_distribution_levers, :lever_group, :string, null: false, default: "", comment: "Case Distribution lever grouping"
  end
end
