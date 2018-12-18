class AddIsDtaToSupplementalClaim < ActiveRecord::Migration[5.1]
  def change
    add_column :supplemental_claims, :is_dta_error, :boolean
  end
end
