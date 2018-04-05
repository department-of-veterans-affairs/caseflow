class AddDispatchedToStationToAppeals < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :dispatched_to_station, :string
  end
end
