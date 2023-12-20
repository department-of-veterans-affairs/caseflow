class AddUpdatedByIdToVirtualHearings < Caseflow::Migration
  def change
    safety_assured do
      add_reference :virtual_hearings, :updated_by, index: false, foreign_key: { to_table: :users }, comment: "The ID of the user who most recently updated the virtual hearing"
    end

    add_safe_index :virtual_hearings, :updated_by_id
  end
end
