class AddPexipToVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    add_column :virtual_hearings, :pexip, :boolean
  end
end
