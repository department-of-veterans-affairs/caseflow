class AddNotesToClaimants < ActiveRecord::Migration[5.2]
  def change
    add_column :claimants, :notes, :text, comment: "Notes why a claimant is not listed."
  end
end
