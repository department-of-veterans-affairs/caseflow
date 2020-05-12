class ChangeColumnVirtualHearingGuestPin < ActiveRecord::Migration[5.2]
  def change
    add_column :virtual_hearings, :guest_pin_long, :bigint, :limit => 5, comment: "Increase the size of the guest pin column"
  end
end
