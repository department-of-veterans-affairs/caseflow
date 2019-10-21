class CreateEndProductCodeUpdates < ActiveRecord::Migration[5.1]
  def change
    create_table :end_product_code_updates, comment: "Caseflow establishes end products in VBMS with specific end product codes. If that code is changed outside of Caseflow, that is tracked here."  do |t|
      t.string :code, null: false, comment: "The new end product code, if it has changed since last checked."
      t.belongs_to :end_product_establishment, null: false
      t.timestamps
    end
  end
end
