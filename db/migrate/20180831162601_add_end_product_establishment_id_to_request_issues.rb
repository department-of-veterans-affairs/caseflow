class AddEndProductEstablishmentIdToRequestIssues < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    add_column :request_issues, :end_product_establishment_id, :integer
    add_index(:request_issues, [:end_product_establishment_id])
  end
end
