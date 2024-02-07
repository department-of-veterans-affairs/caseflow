class AddSctAppealToDistributedCases < ActiveRecord::Migration[5.2]
  def change
    add_column :distributed_cases, :sct_appeal, :boolean
  end
end
