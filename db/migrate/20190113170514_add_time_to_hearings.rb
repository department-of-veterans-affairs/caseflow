class AddTimeToHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :scheduled_time, :time
  end
end
