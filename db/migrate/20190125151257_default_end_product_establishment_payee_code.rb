class DefaultEndProductEstablishmentPayeeCode < ActiveRecord::Migration[5.1]
  def change
    safety_assured do
      execute "UPDATE end_product_establishments SET payee_code='00' WHERE payee_code is null"
      change_column_null :end_product_establishments, :payee_code, false
    end
  end
end
