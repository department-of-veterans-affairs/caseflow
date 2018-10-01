class AddClosedOnToRampClosedAppeals < ActiveRecord::Migration[5.1]
  def change
    add_column :ramp_closed_appeals, :closed_on, :datetime
  end
end
