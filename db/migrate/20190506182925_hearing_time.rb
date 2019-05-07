class HearingTime < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :scheduled_for_time, :string
  end
end
