class AddAutoRemandToSupplementalClaims < ActiveRecord::Migration[6.1]
  def change
    add_column :supplemental_claims, :auto_remand, :boolean, comment: "Indicates if this SupplementalClaim was created as a result of an Auto Remand"
  end
end
