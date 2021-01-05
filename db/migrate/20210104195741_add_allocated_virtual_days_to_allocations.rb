class AddAllocatedVirtualDaysToAllocations < ActiveRecord::Migration[5.2]
  def change
    add_column :allocations,
    :allocated_virtual_days,
    :float,
    comment: "Number of Virtual Hearing Days Allocated"
  end
end
