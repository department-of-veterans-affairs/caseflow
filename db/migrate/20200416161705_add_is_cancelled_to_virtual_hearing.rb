class AddIsCancelledToVirtualHearing < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :virtual_hearings, :request_cancelled, :boolean, default: :false, comment: "Determines whether the user has cancelled the virtual hearing request"
    end
  end
end
