class HearingTime < ActiveRecord::Migration[5.1]
  def change
    add_column :hearing, :scheduled_for_time, :string
  end
end
