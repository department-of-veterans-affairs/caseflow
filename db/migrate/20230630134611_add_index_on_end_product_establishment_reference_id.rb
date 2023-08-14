class AddIndexOnEndProductEstablishmentReferenceId < Caseflow::Migration
  def change
    add_safe_index :end_product_establishments, :reference_id
  end
end
