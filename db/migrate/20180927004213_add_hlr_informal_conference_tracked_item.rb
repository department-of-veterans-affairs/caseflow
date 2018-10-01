class AddHlrInformalConferenceTrackedItem < ActiveRecord::Migration[5.1]
  def change
    add_column :end_product_establishments, :doc_reference_id, :string
    add_column :end_product_establishments, :development_item_reference_id, :string
    add_column :end_product_establishments, :benefit_type_code, :string
  end
end
