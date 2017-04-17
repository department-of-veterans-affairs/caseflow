class ChangeDocumentLabelToCategories < ActiveRecord::Migration
  def change
    remove_column :documents, :label, :integer
    add_column :documents, :category_procedural, :boolean
    add_column :documents, :category_medical, :boolean
    add_column :documents, :category_other, :boolean
  end
end
