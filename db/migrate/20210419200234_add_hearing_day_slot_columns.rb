# frozen_string_literal: true

class AddHearingDaySlotColumns < ActiveRecord::Migration[5.2]
  def change
    add_column :hearing_days, :number_of_slots, :integer
    add_column :hearing_days, :slot_length_minutes, :integer
    add_column :hearing_days, :begins_at, :datetime
  end
end
