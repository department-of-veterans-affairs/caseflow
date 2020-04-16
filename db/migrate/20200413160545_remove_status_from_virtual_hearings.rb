class RemoveStatusFromVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      remove_column :virtual_hearings, :status, :string, comment: "Refactored to calculate status instead of saving"
    end
  end
end
