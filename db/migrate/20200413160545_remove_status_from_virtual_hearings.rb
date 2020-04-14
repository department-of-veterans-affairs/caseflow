class RemoveStatusFromVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :virtual_hearings, :status
    end
  end
end
