class AddClaimantTypeAndNotes < ActiveRecord::Migration[5.2]
  def change
    add_column :claimants, :type, :string, comment: "Type of claimant, such as veteran, dependent, attorney or other."
    add_column :claimants, :notes, :text, comment: "Notes collected for unlisted claimants."
    reversible do |direction|
      direction.up { Claimant.update_all(type: 'Claimant') }
    end
    change_column_null :claimants, :type, false
  end
end
