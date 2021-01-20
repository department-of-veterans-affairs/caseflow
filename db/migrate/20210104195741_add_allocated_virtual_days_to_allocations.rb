class AddAllocatedVirtualDaysToAllocations < ActiveRecord::Migration[5.2]
  def change
    add_column :allocations,
    :allocated_days_without_room,
    :float,
    comment: "Number of Hearing Days Allocated with no Rooms"
  end
end
