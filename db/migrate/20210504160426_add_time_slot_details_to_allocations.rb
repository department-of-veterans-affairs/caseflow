class AddTimeSlotDetailsToAllocations < Caseflow::Migration
  def change
    add_column :allocations, :number_of_slots, :integer, comment: "The number of time slots possible for this allocation"
    add_column :allocations, :slot_length_minutes, :integer, comment: "The length in minutes of each time slot for this allocation"
    add_column :allocations, :first_slot_time, :string, :limit => 5, comment: "The first time slot available for this allocation; interpreted as the local time at Central office or the RO"

    change_table_comment :allocations, "Hearing Day Requests for each Regional Office used for calculation and confirmation of the Build Hearings Schedule Algorithm"
    change_column_comment :allocations, :schedule_period_id, "Hearings Schedule Period to which this request belongs"
    change_column_comment :allocations, :created_at, "Standard created_at/updated_at timestamps"
    change_column_comment :allocations, :updated_at, "Standard created_at/updated_at timestamps"
    change_column_comment :allocations, :regional_office, "Key of the Regional Office Requesting Hearing Days"
    change_column_comment :allocations, :allocated_days, "Number of Video or Central Hearing Days Requested by the Regional Office"

    add_foreign_key :allocations, :schedule_periods, column: "schedule_period_id", validate: false
  end
end
