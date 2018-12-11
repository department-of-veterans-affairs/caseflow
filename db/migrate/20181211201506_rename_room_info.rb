class RenameRoomInfo < ActiveRecord::Migration[5.1]
  def change
    rename_column :hearing_days, :room_info, :room
  end
end
