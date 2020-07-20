class ChangeColumnVirtualHearingGuestPinAndHostPin < ActiveRecord::Migration[5.2]
  def change
    add_column :virtual_hearings, :guest_pin_long, :string, :limit => 11, comment: "Change the guest pin to store a longer pin with the # sign trailing"
    add_column :virtual_hearings, :host_pin_long, :string, :limit => 8, comment: "Change the host pin to store a longer pin with the # sign trailing"
  end
end
