class AddDispatchedToStationToAppeals < ActiveRecord::Migration
  def change
    add_column :appeals, :dispatched_to_station, :string
  end
end
