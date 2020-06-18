class AddClaimantTypeAndNotes < ActiveRecord::Migration[5.2]
  def up
    add_column :claimants, :type, :string, comment: "The class name for the single table inheritance type of Claimant, for example VeteranClaimant, DependentClaimant, AttorneyClaimant, or OtherClaimant."
    change_column_default :claimants, :type, "Claimant"
  end

  def down
    remove_column :claimants, :type
  end
end
