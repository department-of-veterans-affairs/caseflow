class ValidateForeignKeyForEndProductCodeUpdate < Caseflow::Migration
  def change
  	validate_foreign_key "end_product_code_updates", "end_product_establishments"
  end
end
