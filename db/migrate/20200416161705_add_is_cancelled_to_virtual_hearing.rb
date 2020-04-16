class AddIsCancelledToVirtualHearing < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :virtual_hearings, :request_cancelled, :boolean, default: :false
    end
  end
end
