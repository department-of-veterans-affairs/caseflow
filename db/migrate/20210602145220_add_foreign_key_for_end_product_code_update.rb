class AddForeignKeyForEndProductCodeUpdate < Caseflow::Migration
  def change
    add_foreign_key "end_product_code_updates", "end_product_establishments", validate: false
  end
end
