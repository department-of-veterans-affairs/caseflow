# frozen_string_literal: true

class AddHearingDaySlotColumns < Caseflow::Migration
  def change
    add_column :hearing_days, :number_of_slots, :integer, comment: "The number of slots possible for this day"
    add_column :hearing_days, :slot_length_minutes, :integer, comment: "How long each timeslot is for this day"
    add_column :hearing_days, :begins_at_time_string, :string, comment: "in eastern timezone, slots will not appear before this time"
  end
end
