class AddCategoryToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :category_case_summary, :boolean
  end
end
