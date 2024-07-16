class UpdateSupplementalClaims < ActiveRecord::Migration[6.0]
  def change
    safety_assured do
      add_column :supplemental_claims, :type, :string, comment: "Single table inheritanc e column for remands"
    end
  end
end
