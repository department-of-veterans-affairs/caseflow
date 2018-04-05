class ChangeDocumentLabelToInteger < ActiveRecord::Migration[5.1]
  def change
    remove_column :documents, :label, :string
    add_column :documents, :label, :integer
  end
end
