class AddBgsSyncTimeToVeterans < Caseflow::Migration
  def change
    add_column :veterans, :bgs_last_synced_at, :datetime,
               comment: "The last time cached BGS attributes were synced"
  end
end
