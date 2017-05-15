class ChangeDocumentLabelToInteger < ActiveRecord::Migration
  def change
    remove_column :documents, :label, :string
    add_column :documents, :label, :integer
  end
end
