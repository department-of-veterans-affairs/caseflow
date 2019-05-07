class HearingTime < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :scheduled_for_time, :string
    change_column_null :hearings, :scheduled_time, true
  end
end
