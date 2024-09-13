class AddTypeColumnAndIndexToSupplementalClaimsForRemandInheritance < ActiveRecord::Migration[6.1]
  include Caseflow::Migrations::AddIndexConcurrently

  def change
    safety_assured do
      add_column :supplemental_claims, :type, :string, default: "SupplementalClaim", null: false, comment: "The class name for the single table inheritance type of Supplemental Claim for example Remand"
    end

    add_safe_index :supplemental_claims, [:type], name: "index_supplemental_claims_on_type"
  end
end
