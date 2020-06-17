class AddNotesToClaimants < ActiveRecord::Migration[5.2]
  def change
    add_column :claimants, :notes, :text, comment: "This is a notes field for adding claimant not listed and any supplementary information outside of unlisted claimant."
  end
end
