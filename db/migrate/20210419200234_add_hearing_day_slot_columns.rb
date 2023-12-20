# frozen_string_literal: true

class AddHearingDaySlotColumns < Caseflow::Migration
  def change
    add_column :hearing_days, :number_of_slots, :integer, comment: "The number of time slots possible for this day"
    add_column :hearing_days, :slot_length_minutes, :integer, comment: "The length in minutes of each time slot for this day"
    add_column :hearing_days, :first_slot_time, :string, :limit => 5, comment: "The first time slot available; interpreted as the local time at Central office or the RO"
  end
end
